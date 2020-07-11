#!/bin/bash
# Install a built game to the default Linux PICO-8 carts location
# $1: game file path (debug or release, .p8 pr .p8.png)

# check that source and output paths have been provided
if [[ $# -lt 1 ]] ; then
    echo "build.sh takes 1 or 2 params, provided $#:
    \$1: config ('debug' or 'release')
    \$2: optional suffix ('png' for .png cartridge install)"
    exit 1
fi

# Configuration: cartridge
cartridge_stem="picosonic"
version="3.0"
config="$1"; shift

# option "png" will export the png cartridge
if [[ $2 = "png" ]] ; then
	suffix=".png"
else
	suffix=""
fi

cartridge_filepath="build/${cartridge_stem}_v${version}_${config}.p8${suffix}"
carts_dirpath="$HOME/.lexaloffle/pico-8/carts"
install_dirpath="${carts_dirpath}/picosonic"

if [[ ! -f "${cartridge_filepath}" ]]; then
	echo "File ${cartridge_filepath} could not be found, cannot install. Make sure you built it first."
	exit 1
fi

echo "Installing ${cartridge_filepath} in ${install_dirpath} ..."
cp "${cartridge_filepath}" "${install_dirpath}"
echo "Done."
