#pragma once
// Which host button and keys press each PS2 button: the Graphics window's "Controles" tab changes them,
// mksm.ini keeps them (PS2X_PAD_<ini>=<raylib gamepad button>, PS2X_TECLA_<ini>=<key>[,<key>]).
// Only ps2_pad.cpp and ps2_runtime.cpp include this (never ps2_runtime.h).
#include <cstdint>

struct PadBinding
{
    uint16_t bit;        // the PS2 button's bit in the pad data
    const char *name;    // shown in the menu
    const char *iniName; // PS2X_PAD_<iniName>, PS2X_TECLA_<iniName>
    int gamepad;         // raylib GAMEPAD_BUTTON_*, 0 = none
    int key, key2;       // raylib KEY_*, 0 = none
};

constexpr int kPadBindingCount = 16;
// Written only from the window thread while the Graphics window is open, when the game reads no pad
// (g_gfxBlockInput), so the game thread never reads a binding while it changes.
PadBinding *padBindings();              // the current ones, read from the environment on first use
const PadBinding *padBindingDefaults(); // the built-in ones
