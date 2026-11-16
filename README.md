# Mortal Kombat: Shaolin Monks — PS2 static recompilation

**English** · [Português (Brasil)](README.pt-BR.md)

A **static recompilation** of *Mortal Kombat: Shaolin Monks* for **PlayStation 2** (USA, `SLUS-210.87`) to native PC code, built on [**PS2Recomp**](https://github.com/ran-j/PS2Recomp).

This is **not an emulator** and **not a remaster**. The game's MIPS code (its ELF) is translated to C++ and compiled as a native program. The hardware that is not the CPU (GS, VU, DMA, IOP, SPU2) is still emulated by the PS2Recomp runtime, with our own changes on top.

> **This repository contains no game data.** No ISO, ELF, generated code, recordings or assets, and it does not help you get them. You need your own copy of the game.

## Status

| Area | State |
|---|---|
| Recompile the ELF (13,651 C++ files) and build the runtime | ✅ Done |
| Boot, threads, disc reads (CRI ADXF / `GAMEDATA.WAD`) | ✅ Done |
| Save screens, main menu, character select | ✅ Done |
| First 3D stage (Goro's Lair) with HUD, pause and map | ✅ Done |
| Music and voices (ADX) | ✅ Working |
| GS on the GPU (Vulkan) | ✅ New batching renderer at 2x by default (per-pixel mipmaps); the old exact renderer stays behind `PS2X_GS_HW=0` |
| VU1 on its own thread, x86-64 JIT | ✅ Working |
| Full speed (60 fields/s) | 🟡 Right speed everywhere (no slow motion); on a GTX 1050 gameplay runs ~55–60 frames/s, heavy scenes drop frames instead (`PLANO_DESEMPENHO.md`, N20) |
| CRI movies (FMV) | ✅ Intro and all 8 movies play; Start skips |
| Memory card (save and load) | ✅ Working (files in `extraido_full/mc0/`) |
| Gameplay sound | ✅ 48 kHz without warble; SPU2 reverb approximated (`PS2X_REVERB`) |
| Movie sound | ✅ Played straight from the `.SFD` files (no hiss) |
| Kung Lao as partner | ✅ Visible (used to be invisible) |
| Every other stage tested start to finish | ❌ To do |
| Windows build | 🟡 Cross-built with MinGW-w64 from Linux (`scripts/build_windows.sh`); runs in Wine (menus, Versus, RPG), not yet tried on real Windows |
| Floors, walls and light rays in Goro's Lair | ✅ As in the original (the VIF now runs ahead of VU1: the game sends each batch's colors right after starting it) |
| Liu Kang spinning while standing (an R5900 MMI instruction read the wrong register) | ✅ Fixed |
| Heavy cutscene moments (Raiden arriving) | 🟡 Drop to ~35 frames/s for a few seconds, with both renderers (EE/VU1 limit, N20) |
| RPG mode (levels and attribute points) | 🟡 Implemented, Single Player and Ko-op (see [RPG mode](#rpg-mode-optional)); balance still being tested |
| Versus mode fighters | ✅ All 8 unlocked by default (`MKSM_VERSUS_TODOS=0` restores the original unlocks); and any of them (plus Goro, Shang Tsung and a lava demon, experimental, and Ermac and three cut characters that walk but have no attacks) can be picked for a new story or Ko-op game with **L1/R1** on the difficulty screen; story compatibility still being tested ([`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md)) |
| Fullscreen | ✅ F11 |
| Higher internal resolution | ✅ New batching renderer at 2x by default, as fast as the old one; `PS2X_GS_HW=0` goes back to the old one, `PS2X_SCALE=1..4` picks the scale |
| Graphics menu for weaker PCs | ✅ R3 in menus/pause (or F1): internal resolution, FXAA, upscale filter, field blend, renderer; saved to `mksm.ini` |
| Widescreen | ✅ 16:9 in the Graphics menu or `PS2X_WIDESCREEN=1` (3D gets the wider view; 2D/HUD stretches, as in PCSX2; movies stay 4:3) |

Detailed state: [`ESTADO.md`](ESTADO.md). Performance plan with measurements: [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md).

## Requirements

- Your own copy of the game (PS2, USA, `SLUS-210.87`).
- Linux (tested on Arch/CachyOS with GCC). A Windows build is cross-compiled from Linux with MinGW-w64 (`scripts/build_windows.sh`); building natively on Windows has not been tried.
- `git`, `cmake`, `ninja`, `7z`, `g++`, `glslc` (Vulkan SDK / shaderc), `libvulkan`.
- A Vulkan GPU. Optional but much faster: `VK_EXT_fragment_shader_interlock` (NVIDIA since Maxwell, recent AMD/Intel). Without Vulkan the CPU renderer is used.
- ~5 GB of RAM per build job and a few hours for the first build (the generated code is huge).

> **There is no ready-made executable to download, and there won't be.** The executable contains the game's translated code, so shipping it would mean shipping the game. Everyone builds from their own copy with the script below.

## Build and run

One command extracts the ISO, fetches PS2Recomp at the pinned commit, applies our patches, recompiles the ELF and builds everything:

```bash
scripts/instalar.sh "path/to/your.iso"
```

Use `JOBS=1` if you run out of memory. If it stops halfway, run it again: finished steps are skipped.

Play:

```bash
scripts/jogar.sh
```

It reads optional settings from `mksm.ini` in the project root (one `VARIABLE=value` per line; the list is at the top of [`scripts/jogar.sh`](scripts/jogar.sh)). Keys: **F11** fullscreen, **F10** screenshot (`capturas/`), **F9** records the current scene for bug reports (`gsrec/`, game data: don't share it publicly). **Graphics menu:** **R3** on the controller in menus, the Select pause and the map, or **F1** anytime (internal resolution, 16:9, FXAA, upscale filter, field blend, renderer; saved to `mksm.ini`). **F12** opens the debug panel.

**Portable folders:** after building, `scripts/empacotar_linux.sh` makes `portatil/MKSM-linux` (runs on another Linux without installing anything) and `scripts/build_windows.sh` makes `portatil/MKSM-windows` (double-click `Jogar.bat`). They contain your game files: keep them for yourself.

**Laptops with two GPUs:** the window may open on the integrated GPU. Prefix the command with `prime-run` (or `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`).

**Controller:** a regular USB/Bluetooth gamepad works; the analog sticks have a 25% dead zone (`PS2X_DEADZONE` in `mksm.ini`).

Useful environment variables (all listed in [`ARQUITETURA.md`](ARQUITETURA.md) §6):

| Variable | Effect |
|---|---|
| `MKSM_SKIP_INTRO=1` | Skips the intro videos |
| `PS2X_VOL_MASTER`, `PS2X_VOL_MUSIC`, `PS2X_VOL_SFX` | Volumes, 0–100 |
| `PS2X_REVERB=22` | Echo on sound effects (0 turns it off) |
| `PS2X_FXAA=0` | No edge smoothing (on by default) |
| `PS2X_GS_HW=0` | Old renderer (PS2 resolution, bit-exact) instead of the new one |
| `PS2X_SCALE=1` | Internal resolution of the new renderer, 1–4 (default 2; 1 for weak GPUs) |
| `PS2X_WIDESCREEN=1` | 16:9 (wider 3D view; 2D/HUD stretches; movies stay 4:3) |
| `PS2X_RUMBLE=0` | No controller vibration |
| `PS2X_DEINTERLACE=0` | Shows one field at a time instead of blending both (harsher image) |
| `PS2X_UNCAPPED=1` | No real-time cap (throughput testing; the game speeds up) |
| `PS2X_PERF=1` | Prints fps, GS and GPU load and where each frame's time goes, every 2 s |
| `PS2X_PIN=0` | Don't pin the four busy threads to separate physical cores |
| `PS2X_GS_GPU=0` | With `PS2X_GS_HW=0`: the old renderer on the CPU only |
| `PS2X_GS_RASTER=0` | GPU compute tiles instead of the rasterizer |
| `PS2X_VU1_THREAD=0` | VU1 on the game thread |

## Other fighters

- **Versus mode:** all 8 fighters (Liu Kang, Kung Lao, Sub-Zero, Scorpion, Baraka, Reptile, Kitana, Johnny Cage) come unlocked. `MKSM_VERSUS_TODOS=0` in `mksm.ini` restores the original unlocks.
- **Story and Ko-op with another fighter:** on a **new game**, on the *Select Difficulty* screen, each player presses **L1/R1** on their own controller (**Q/E** on the keyboard for player 1) to pick a fighter. The choice is saved with the game and can't be changed afterwards, so bought moves never mix between characters.
- **List:** the 8 Versus fighters. Goro, Shang Tsung and a lava demon are marked experimental: they load and attack, but they are big or odd.
- **Not perfect yet:** Versus fighters were made for 1-on-1 fights. Their basic attacks work in the story, but the move shop, story fatalities and cutscenes (which still show the monks) may not fit. Status and character IDs: [`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md).

## RPG mode (optional)

An optional mode, chosen only when starting a new game, where experience gives **levels** and each level gives an **attribute point**. The game's own economy does not change: enemies give the same XP and moves cost the same.

- **Turn it on:** Single Player or Ko-op → character → on *Select Difficulty*, put the cursor on **Hard** and press **L3** (**F2** on the keyboard). A gold "RPG" appears next to Hard. RPG games are always Hard, with tougher enemies at the start (+30% damage and +30% health), so the early game is harder than Hard and gets easier as you grow.
- **Levels:** the level comes from all the XP earned (buying moves doesn't lower it). Level 1→2 costs 300 XP, then 400, 550, 750... up to level 100. The level and progress (`Nv 3 · 120/550`) show above the "EXP" counter; in Ko-op each player has their own.
- **Attributes** (1 point per level, up to 20 each for now): Strength (+5% damage dealt), Defense (−3% damage taken), Health (+5% max health), Life steal (heals 1% of the damage dealt), Regeneration (0.1% of max health per second), Wisdom (+3% XP toward levels). Movement speed is never touched, so moves, combos and hit boxes stay the original.
- **Spend points:** Select pause → **R3** (or **F1**) → **RPG** tab (L1/R1 switch tabs). X spends a point; "Redistribuir pontos" (X twice) gives them all back. In Ko-op, left/right picks the player.
- **Saves:** a save made in RPG mode stays RPG. The *Load Game* screen tags it "RPG · Nv N". The RPG data lives next to `mksm.ini` in `rpg_mc0_slot<n>.ini` (one per save slot); the memory card save itself is untouched and still opens without the mode. Copy those files along with `mc0/` when you back up.
- **Tuning:** every number (XP curve, effect per point, caps, enemy boost) is a `RPG_*` key in `mksm.ini` (listed at the top of [`scripts/jogar.sh`](scripts/jogar.sh)). With the mode off, the game runs exactly as the original.
- Design, addresses and test status: [`PLANO_RPG.md`](PLANO_RPG.md).

## How the repository is organized

PS2Recomp is **not vendored**. `scripts/aplicar_patches.sh` clones it at the commit in [`patches/UPSTREAM_COMMIT`](patches/UPSTREAM_COMMIT) and applies [`patches/runtime_atual.diff`](patches/runtime_atual.diff) plus the new files listed in [`patches/arquivos.txt`](patches/arquivos.txt). The `PS2Recomp/` folder that results is ignored by git; you work there and run `scripts/atualizar_patches.sh` to bring your changes back into `patches/`.

| Path | What it is |
|---|---|
| `sm.toml` | PS2Recomp configuration for this game (function stubs, overrides, idle loops) |
| `patches/` | Our changes to the PS2Recomp runtime, IOP, recompiler and tests |
| `scripts/` | Build, patch and test helpers |
| [`ARQUITETURA.md`](ARQUITETURA.md) | Architecture: threads, locks, the path of a frame, timing, game traps, testing without booting the game. **Start here.** |
| [`PLANO_DESEMPENHO.md`](PLANO_DESEMPENHO.md) | The active plan: performance, image, open tasks, measurements |
| [`PLANO_RPG.md`](PLANO_RPG.md) | The optional RPG mode: design, game addresses, test status |
| [`PLANO_PERSONAGENS.md`](PLANO_PERSONAGENS.md) | Versus fighters: unlocks, IDs, plan to play them in the story |
| [`PLANO.md`](PLANO.md) | History: the investigation log up to 13/11, with the evidence for each fix |
| [`MODDING.md`](MODDING.md) | Game addresses and formats (level select, stage data, bloom...) |
| [`ESTADO.md`](ESTADO.md) | Technical state and manual build steps |
| `notas/` | Investigation notes |

The technical documents are in Portuguese. Issues and pull requests in English or Portuguese are both welcome.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). In short: never commit game data, keep the renderer bit-exact (there are replay tests for that), and keep the docs in sync with the code.

## License

[GPL-3.0](LICENSE), the same as PS2Recomp, from which `patches/` derives.

## Credits

- [PS2Recomp](https://github.com/ran-j/PS2Recomp) by ran-j and contributors: the recompiler and runtime this project builds on.
- *Mortal Kombat: Shaolin Monks* © Midway / Warner Bros. Interactive Entertainment. This is a non-commercial fan project with no affiliation to the rights holders.
