#!/bin/bash

# Build a PICO-8 cartridge for the integration tests.
# This is essentially a proxy script for pico-boots/scripts/build_cartridge.sh with the right parameters.

# Extra options are passed to build_cartridge.sh (with $@).
# This is useful in particular for --symbols.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_src_path="$(dirname "$0")/src"
data_path="$(dirname "$0")/data"
build_output_path="$(dirname "$0")/build"

# Configuration: cartridge
author="hsandt"
title="pico-sonic itests (all)"
cartridge_stem="picosonic_itest_all"
version="3.2"
config='itest'
# symbols='assert,log,visual_logger,tuner,profiler,mouse,itest'
# cheat needed to set debug motion mode
# symbols='assert,log,itest,cheat'
# attempt to reduce char count (working at 64000 chars for now)
symbols='log,itest,cheat'

# Build from itest main for all itests
"$picoboots_scripts_path/build_cartridge.sh"               \
  "$game_src_path" itest_main.lua itests                   \
  -d "$data_path/data.p8" -M "$data_path/metadata.p8"      \
  -a "$author" -t "$title"                                 \
  -p "$build_output_path"                                  \
  -o "${cartridge_stem}_v${version}"                       \
  -c "$config"                                             \
  -s "$symbols"                                            \
  --minify-level 2
