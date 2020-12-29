#!/bin/bash
# Install a specific cartridge and data cartridges to the default
#  PICO-8 carts location
# This is required if you changed data or build for the first time for a given config,
#  as install_single_cartridge.sh will not copy data along and is not reliable alone.

# Usage: install_single_cartridge_with_data.sh config [png]
#   cartridge_suffix  'titlemenu', 'stage_intro', 'ingame' or 'stage_clear'
#   config            build config (e.g. 'debug' or 'release'. Default: 'debug')
#   png 		          if passed, the .png cartridge is installed

# Currently only supported on Linux

# png option is legacy for p8tool. It works in theory but in practice,
#  since p8tool fails to build .p8.png properly, png will be directly
#  saved from PICO-8 with export_cartridge_release.p8 into PICO-8 carts folder

# Configuration: paths
game_scripts_path="$(dirname "$0")"

# check that source and output paths have been provided
if ! [[ $# -ge 1 &&  $# -le 3 ]] ; then
    echo "build.sh takes 1 or 2 params, provided $#:
    \$1: cartridge_suffix ('titlemenu', 'stage_intro', 'ingame' or 'stage_clear')
    \$2: config ('debug', 'release', etc. Default: 'debug')
    \$3: optional suffix ('png' for .png cartridge install)"
    exit 1
fi

# Configuration: cartridge
version="5.1"
cartridge_suffix="$1"; shift
config="$1"; shift

# option "png" will export the png cartridge
if [[ $1 = "png" ]] ; then
	suffix=".png"
else
	suffix=""
fi

# note that we don't add the data/data_stage*.p8 cartridges because
# install_single_cartridge.sh for ingame will install all data cartridges anyway
# (and said script is really meant for built cartridges as it refers to build path)
"$game_scripts_path/install_single_cartridge.sh" "$cartridge_suffix" "$config" "$suffix"

# recompute same install dirpath as used in install_single_cartridge.sh
# (no need to mkdir -p "${install_dirpath}", it must have been created in said script)
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/picosonic/v${version}_${config}"

# Also copy data cartridges
echo "Copying data cartridges data/data_*.p8 in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp data/data_*.p8 "${install_dirpath}/"
