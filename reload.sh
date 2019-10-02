#!/bin/bash

# Try to find a running PICO-8 session and reload it.
# Requires xdotool (mostly Linux).

# This is often used in combination with a build script to "hot reload" a modified cartridge.
# However, it only makes sense if the built cartridge is the same as the one currently run.

# --sync makes sure the window is active before sending the key, but it gets stuck
# if no matching window is found, so timeout makes sure it doesn't happen
timeout 0.15 xdotool search --sync --class pico8 windowactivate key ctrl+r &&
	echo "Reloaded pico8"
