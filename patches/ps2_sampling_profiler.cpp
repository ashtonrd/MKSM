// Self-time sampling profiler for hosts without perf. PS2X_PROFILE=<seconds>
// waits that long, samples every 1 ms of CPU time for 20 s and writes the raw
// instruction pointers to ps2_profile.txt (resolved with nm by a script).
// PS2X_PROFILE_THREAD=<name>[,<name>...] samples those threads (e.g. GameThread,VU1Thread), one file each.
// PS2X_PROFILE=tecla: each F8 press (ps2_runtime.cpp) samples 15 s, into PS2X_CAPTURE_DIR if set.
// Each sample line is "<rip> <[rsp]> <up to 4 stack words that point into the executable>":
// [rsp] is the caller when rip is in a leaf; the scan finds who called into libc (no unwinder needed).
#include <algorithm>
#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dirent.h>
#include <string>
#include <sys/syscall.h>
#include <sys/time.h>
#include <unistd.h>
#include <thread>
#include <ucontext.h>
#include <signal.h>
#include <time.h>
#include <vector>

extern "C" char __executable_start, etext;

extern std::atomic<int> g_profileRequests; // ps2_runtime.cpp: F8 presses

namespace
{
    constexpr size_t kMaxSamples = 200000u;
    constexpr int kMaxThreads = 4;
    uintptr_t g_samples[kMaxSamples];
    uintptr_t g_stackTop[kMaxSamples]; // [rsp]: the caller of a leaf like memcpy
    constexpr size_t kScan = 4u;
    uintptr_t g_stackScan[kMaxSamples][kScan];
    uint8_t g_sampleThread[kMaxSamples];
    std::atomic<size_t> g_count{0u};
    long g_tids[kMaxThreads] = {};
    int g_threadCount = 0;

    long findThread(const char *name)
    {
        DIR *tasks = opendir("/proc/self/task");
        long found = 0;
        unsigned long long bestCpu = 0;
        while (dirent *entry = tasks != nullptr ? readdir(tasks) : nullptr)
        {
            std::FILE *comm = std::fopen((std::string("/proc/self/task/") + entry->d_name + "/comm").c_str(), "r");
            if (comm == nullptr)
                continue;
            char line[64]{};
            if (std::fgets(line, sizeof(line), comm) != nullptr && std::string(line) == std::string(name) + "\n")
            {
                // Several threads can share a name (the presentation backend has its own idle
                // GSWorker): keep the busiest, by utime + stime from /proc/self/task/<tid>/stat.
                unsigned long long cpu = 0;
                if (std::FILE *stat = std::fopen((std::string("/proc/self/task/") + entry->d_name + "/stat").c_str(), "r"))
                {
                    char buffer[1024]{};
                    if (std::fgets(buffer, sizeof(buffer), stat) != nullptr)
                        if (const char *close = std::strrchr(buffer, ')'))
                        {
                            unsigned long long utime = 0, stime = 0;
                            if (std::sscanf(close + 2, "%*c %*d %*d %*d %*d %*d %*u %*u %*u %*u %*u %llu %llu", &utime, &stime) == 2)
                                cpu = utime + stime;
                        }
                    std::fclose(stat);
                }
                if (found == 0 || cpu > bestCpu)
                    found = std::atol(entry->d_name), bestCpu = cpu;
            }
            std::fclose(comm);
        }
        if (tasks != nullptr)
            closedir(tasks);
        return found;
    }

    void onProfileSignal(int, siginfo_t *, void *context)
    {
        const long tid = syscall(SYS_gettid);
        int thread = -1;
        for (int i = 0; i < g_threadCount; ++i)
            if (g_tids[i] == tid)
                thread = i;
        if (g_threadCount != 0 && thread < 0)
            return;
        const size_t index = g_count.fetch_add(1u, std::memory_order_relaxed);
        if (index < kMaxSamples)
        {
            const auto &regs = static_cast<ucontext_t *>(context)->uc_mcontext.gregs;
            g_samples[index] = static_cast<uintptr_t>(regs[REG_RIP]);
            g_sampleThread[index] = static_cast<uint8_t>(thread < 0 ? 0 : thread);
            const auto *stack = reinterpret_cast<const uintptr_t *>(regs[REG_RSP]);
            g_stackTop[index] = stack[0];
            const auto low = reinterpret_cast<uintptr_t>(&__executable_start), high = reinterpret_cast<uintptr_t>(&etext);
            // shortcut: 64 words is always inside the mapped stack of our threads; stale words can show up as callers.
            for (size_t word = 0u, found = 0u; word < 64u && found < kScan; ++word)
                if (stack[word] >= low && stack[word] < high)
                    g_stackScan[index][found++] = stack[word];
        }
    }

    // Samples the listed threads (or the whole process) for some seconds; one file per thread.
    void profileOnce(const std::string &prefix, int seconds)
    {
        std::vector<std::string> names;
        if (const char *only = std::getenv("PS2X_PROFILE_THREAD"))
            for (const char *c = only; *c;)
            {
                const char *end = std::strchr(c, ',');
                names.emplace_back(c, end ? end - c : std::strlen(c));
                c = end ? end + 1 : c + std::strlen(c);
            }
        g_threadCount = 0;
        std::vector<std::string> found;
        for (const std::string &name : names)
            if (const long tid = findThread(name.c_str()); tid != 0 && g_threadCount < kMaxThreads)
                g_tids[g_threadCount++] = tid, found.push_back(name);
        g_count.store(0u);
        struct sigaction action{};
        action.sa_sigaction = onProfileSignal;
        action.sa_flags = SA_SIGINFO | SA_RESTART;
        sigaction(SIGPROF, &action, nullptr);
        // A timer on each thread's own CPU clock, signalling that thread. ITIMER_PROF counts the
        // whole process and lands on any thread, so with many busy threads a chosen one almost
        // never got a sample.
        std::vector<timer_t> timers;
        for (int i = 0; i < g_threadCount; ++i)
        {
            const clockid_t clock = static_cast<clockid_t>((~static_cast<unsigned long>(g_tids[i]) << 3) | 6u); // CPUCLOCK_SCHED of a tid
            sigevent event{};
            event.sigev_notify = SIGEV_THREAD_ID;
            event.sigev_signo = SIGPROF;
            event._sigev_un._tid = static_cast<pid_t>(g_tids[i]);
            timer_t timer{};
            if (timer_create(clock, &event, &timer) == 0)
            {
                itimerspec every{{0, 1000000}, {0, 1000000}};
                timer_settime(timer, 0, &every, nullptr);
                timers.push_back(timer);
            }
        }
        if (timers.empty())
        {
            itimerval timer{{0, 1000}, {0, 1000}};
            setitimer(ITIMER_PROF, &timer, nullptr);
        }
        std::this_thread::sleep_for(std::chrono::seconds(seconds));
        for (timer_t timer : timers)
            timer_delete(timer);
        itimerval stop{};
        setitimer(ITIMER_PROF, &stop, nullptr);
        const size_t total = std::min(g_count.load(), kMaxSamples);
        const int files = std::max(1, static_cast<int>(found.size()));
        for (int t = 0; t < files; ++t)
        {
            const std::string path = prefix + (found.size() <= 1 ? std::string() : "_" + found[t]) + ".txt";
            std::FILE *out = std::fopen(path.c_str(), "w");
            if (out == nullptr)
                continue;
            std::FILE *maps = std::fopen("/proc/self/maps", "r");
            char line[512];
            while (maps != nullptr && std::fgets(line, sizeof(line), maps) != nullptr)
                std::fprintf(out, "base %s", line);
            if (maps != nullptr)
                std::fclose(maps);
            for (size_t i = 0u; i < total; ++i)
                if (found.empty() || g_sampleThread[i] == t)
                    std::fprintf(out, "%zx %zx %zx %zx %zx %zx\n", g_samples[i], g_stackTop[i], g_stackScan[i][0],
                                 g_stackScan[i][1], g_stackScan[i][2], g_stackScan[i][3]);
            std::fclose(out);
        }
        std::fprintf(stderr, "[perfil] %s: %zu amostras\n", prefix.c_str(), total);
    }

    struct ProfilerStarter
    {
        ProfilerStarter()
        {
            const char *delay = std::getenv("PS2X_PROFILE");
            if (delay == nullptr)
                return;
            if (std::strcmp(delay, "tecla") == 0) // one profile per F8 press
            {
                std::thread([]
                            {
                    const char *dir = std::getenv("PS2X_CAPTURE_DIR");
                    for (int done = 0;; )
                    {
                        if (g_profileRequests.load(std::memory_order_relaxed) <= done)
                        {
                            std::this_thread::sleep_for(std::chrono::milliseconds(100));
                            continue;
                        }
                        done = g_profileRequests.load(std::memory_order_relaxed);
                        profileOnce((dir ? std::string(dir) + "/" : std::string()) + "ps2_profile_" + std::to_string(done), 15);
                    } })
                    .detach();
                return;
            }
            const int seconds = std::atoi(delay);
            std::thread([seconds]
                        {
                std::this_thread::sleep_for(std::chrono::seconds(seconds));
                profileOnce("ps2_profile", 20); })
                .detach();
        }
    } g_profilerStarter;
}
