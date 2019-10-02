#!/bin/bash

# Build a PICO-8 cartridge for the released game.
# This is essentially a proxy script for pico-boots/scripts/build_game.sh with the right parameters.

# Configuration: paths
picoboots_scripts_path="$(dirname "$0")/pico-boots/scripts"
game_src_path="$(dirname "$0")/src"
data_path="$(dirname "$0")/data"
build_output_path="$(dirname "$0")/build"

# Configuration: cartridge
author="hsandt"
title="pico-sonic"
cartridge_stem="picosonic"
version="3.0"

# Build from main
"$picoboots_scripts_path/build_game.sh"                    \
  "$game_src_path" main.lua                                \
  -d "$data_path/data.p8" -M "$data_path/metadata.p8"      \
  -a "$author" -t "$title"                                 \
  -o "$build_output_path/${cartridge_stem}_v${version}.p8" \
  --minify
