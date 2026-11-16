#pragma once

#include <atomic>
#include <cstdint>

// PS2X_PERF=1 prints, every 2 s, how fast each part runs: window frames, game frames,
// vsyncs, how busy the GS was and how long the game waited for it. Counters are
// cheap atomics; the timed ones are only measured when the meter is on.
namespace ps2_perf
{
    struct Counters
    {
        std::atomic<uint64_t> windowFrames{0};
        std::atomic<uint64_t> newImages{0}; // window frames that show a newly completed game frame
        std::atomic<uint64_t> gameFrames{0};
        std::atomic<uint64_t> worstFrameGapNs{0}; // longest wait between two game frames (a stutter)
        std::atomic<uint64_t> imageAgeNs{0};      // sum, over the new images shown, of field done -> window shows it
        std::atomic<uint64_t> vsyncs{0};
        std::atomic<uint64_t> gsBusyNs{0};
        std::atomic<uint64_t> eeWaitingGsNs{0};
        // [perf] quadro: where each game frame's time goes (only measured with PS2X_PERF)
        std::atomic<uint64_t> eeWaitingVu1Ns{0};  // EE in ps2_vu1_thread::sync
        std::atomic<uint64_t> eeWaitingFrontNs{0}; // EE waiting for the GS frontend (CSR, drain, full ring)
        std::atomic<uint64_t> vu1WaitingFrontNs{0};
        std::atomic<uint64_t> vu1BusyNs{0};
        std::atomic<uint64_t> gsDecodeNs{0};       // GS frontend decoding packets (not its spin)
        std::atomic<uint64_t> hwWorkerBusyNs{0};   // GSHwWorker drawing
    };

    Counters &counters();
    bool enabled();
    uint64_t nowNs();
    // Starts the reporter thread once, if PS2X_PERF is set.
    void startReporter();

    // The four busy threads (game, VU1, GS frontend, GS worker) each on their own physical
    // core: two of them sharing a core's hyperthreads run ~40% slower (i7-7700HQ: 54 -> 59.5
    // frames/s in gameplay). No-op with fewer than 4 cores or PS2X_PIN=0.
    enum class HeavyThread : unsigned { Game = 0, Vu1 = 1, GsWorker = 2, GsFrontend = 3 };
    void pinHeavyThread(HeavyThread role);
}
