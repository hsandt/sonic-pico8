#!/bin/bash
# Install a specific cartridge for the game to the default
#  PICO-8 carts location
# This is required if you need to play with multiple carts,
#  as other carts will only be loaded in PICO-8 carts location

# Usage: install_single_cartridge.sh cartridge_suffix config [png]
#   cartridge_suffix  'titlemenu' or 'ingame'
#   config            build config (e.g. 'debug' or 'release')
#   png 		      if passed, the .png cartridge is installed

# Currently only supported on Linux

# png option is legacy for p8tool. It works in theory but in practice,
#  since p8tool fails to build .p8.png properly, png will be directly
#  saved from PICO-8 with export_cartridge_release.p8 into PICO-8 carts folder

# check that source and output paths have been provided
if ! [[ $# -ge 1 &&  $# -le 3 ]] ; then
    echo "build.sh takes 1 to 2 params, provided $#:
    \$1: cartridge_suffix ('titlemenu' or 'ingame')
    \$2: config ('debug', 'release', etc.)
    \$3: optional suffix ('png' for .png cartridge install)"
    exit 1
fi

# Configuration: cartridge
cartridge_stem="picosonic"
version="4.2"
cartridge_suffix="$1"; shift
config="$1"; shift

# option "png" will export the png cartridge
if [[ $1 = "png" ]] ; then
	suffix=".png"
else
	suffix=""
fi

output_path="build/v${version}_${config}"
cartridge_filepath="${output_path}/${cartridge_stem}_${cartridge_suffix}.p8${suffix}"
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/picosonic/v${version}_${config}"

if [[ ! -f "${cartridge_filepath}" ]]; then
	echo "File ${cartridge_filepath} could not be found, cannot install. Make sure you built it first."
	exit 1
fi

mkdir -p "${install_dirpath}"

echo "Installing ${cartridge_filepath} in ${install_dirpath} ..."
# trailing slash just to make sure we copy to a directory
cp "${cartridge_filepath}" "${install_dirpath}/"

# Also copy data stage cartridges for extended map
# Since copy is very fast, we do this even when instaling titlemenu cartridge to simplify
cp data/data_stage*.p8 "${install_dirpath}/"

echo "Done."
