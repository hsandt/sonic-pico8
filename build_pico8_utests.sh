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
title="pico-sonic pico8 utests (all)"
cartridge_stem="picosonic_pico8_utests_all"
version="3.1"
config='debug'
symbols='assert,log'

# Build from itest main for all pico8 utests
# Note that a pico8 utest_main build is much smaller than a normal build,
# so minification is not required in general; however it is useful to spot
# issues in the real build like unprotected sprite animation keys being minified
"$picoboots_scripts_path/build_cartridge.sh"               \
  "$game_src_path" utest_main.lua utests                   \
  -d "$data_path/data.p8" -M "$data_path/metadata.p8"      \
  -a "$author" -t "$title"                                 \
  -p "$build_output_path"                                  \
  -o "${cartridge_stem}_v${version}"                       \
  -c "$config"                                             \
  -s "$symbols"                                            \
  --minify-level 2
