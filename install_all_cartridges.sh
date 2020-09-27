#!/bin/bash
# Install all cartridges for the game to the default
#  PICO-8 carts location
# This is required if you need to play with multiple carts,
#  as other carts will only be loaded in PICO-8 carts location

# Usage: install_all_cartridges.sh config [png]
#   config            build config (e.g. 'debug' or 'release')
#   png 		      if passed, the .png cartridges are installed

# Currently only supported on Linux

# png option is legacy for p8tool. It works in theory but in practice,
#  since p8tool fails to build .p8.png properly, png will be directly
#  saved from PICO-8 with export_cartridge_release.p8 into PICO-8 carts folder

# Configuration: paths
game_scripts_path="$(dirname "$0")"

# check that source and output paths have been provided
if ! [[ $# -ge 1 &&  $# -le 2 ]] ; then
    echo "build.sh takes 1 or 2 params, provided $#:
    \$1: config ('debug', 'release', etc.)
    \$2: optional suffix ('png' for .png cartridge install)"
    exit 1
fi

config="$1"; shift

# option "png" will export the png cartridge
if [[ $1 = "png" ]] ; then
	suffix=".png"
else
	suffix=""
fi

"$game_scripts_path/install_single_cartridge.sh" titlemenu "$config" "$suffix"
"$game_scripts_path/install_single_cartridge.sh" ingame "$config" "$suffix"
