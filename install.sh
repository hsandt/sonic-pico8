#!/bin/bash
# Install a built game to the default Linux PICO-8 carts location
# $1: game file path (debug or release, .p8 pr .p8.png)

# check that source and output paths have been provided
if [[ $# -lt 1 ]] ; then
    echo "build.sh takes 1 param, provided $#:
    \$1: game release file path (must contain .p8 pr .p8.png)"
    exit 1
fi

if [[ $1 == *..* ]]; then
	echo "$0: build path is unsafe: '$1'"
	exit 1
fi

BUILT_GAME_FILEPATH="build/$1"
CARTS_DIRPATH="$HOME/.lexaloffle/pico-8/carts"

if [[ ! -f "${BUILT_GAME_FILEPATH}" ]]; then
	echo "File ${BUILT_GAME_FILEPATH} could not be found, cannot install. Make sure you built it first."
	exit 1
fi

echo "Installing ${BUILT_GAME_FILEPATH} to ${CARTS_DIRPATH} ..."
cp "${BUILT_GAME_FILEPATH}" "${CARTS_DIRPATH}"
