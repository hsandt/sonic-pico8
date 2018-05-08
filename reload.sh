#!/bin/bash
# --sync makes sure the window is active before sending the key, but it gets stuck
# if no matching window is found, so timeout makes sure it doesn't happen
timeout 0.15 xdotool search --sync --class pico8 windowactivate key ctrl+r &&
echo "Reloaded pico8"
