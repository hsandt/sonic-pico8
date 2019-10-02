#!/bin/bash

# Run game.p8 with PICO-8 executable
# Pass any extra arguments to pico8

# Configuration: cartridge
cartridge_stem="picosonic"
version="3.0"

run_cmd="pico8 -run build/${cartridge_stem}_v${version}.p8 -screenshot_scale 4 -gif_scale 4 $@"
echo "> $run_cmd"
bash -c "$run_cmd"
