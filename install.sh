#!/bin/bash
# Install a built game to the default Linux PICO-8 carts location
# $1: game file path (debug or release, .p8 pr .p8.png)

# check that source and output paths have been provided
if [[ $# -lt 1 ]] ; then
    echo "build.sh takes 1 param, provided $#:
    \$1: config ('debug' or 'release')"
    exit 1
fi

# option "png" will export the png cartridge
if [[ $2 = "png" ]] ; then
	SUFFIX=".png"
else [[ $2 = "solo" ]]
	SUFFIX=""
fi

. helper/config_helper.sh

# will define: MAIN_SOURCE_BASENAME, OUTPUT_BASENAME, REPLACE_ARG_SUBSTITUTES
define_build_vars "main"

if [[ $? -ne 0 ]]; then
    echo "define_build_vars failed, STOP."
    exit 1
fi

. helper/path_helper.sh

if is_unsafe_path "$OUTPUT_BASENAME"; then
    echo "$0: build path is unsafe: '$OUTPUT_BASENAME'"
    exit 1
fi

BUILT_GAME_FILEPATH="build/${OUTPUT_BASENAME}_$1.p8${SUFFIX}"
CARTS_DIRPATH="$HOME/.lexaloffle/pico-8/carts"

if [[ ! -f "${BUILT_GAME_FILEPATH}" ]]; then
	echo "File ${BUILT_GAME_FILEPATH} could not be found, cannot install. Make sure you built it first."
	exit 1
fi

echo "Installing ${BUILT_GAME_FILEPATH} to ${CARTS_DIRPATH} ..."
cp "${BUILT_GAME_FILEPATH}" "${CARTS_DIRPATH}"
