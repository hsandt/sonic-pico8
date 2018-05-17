#!/bin/bash
# $1: source file (from src/, no .lua extension)
# $2: output file (from build/, no .p8 extension)


# check that source and output paths have been provided
if [[ $# -lt 2 ]] ; then
    echo 'build.sh takes 2 params:
    $1: source file (from src/, no .lua extension)
    $2: output file (from build/, no .p8 extension)'
    exit 1
fi

OUTPUT_FILEPATH="build/$2.p8"

# clean up existing file (p8tool doesn't support parsing file with non-ascii chars, even just to replace appropriate blocks)
rm -f "$OUTPUT_FILEPATH"

mkdir -p build
# build the game from the different modules
p8tool build --lua "src/$1.lua" --lua-path="?.lua;$(pwd)/src/?.lua" --gfx "data/data.p8" --gff "data/data.p8" --map "data/data.p8" --sfx "data/data.p8" --music "data/data.p8" "$OUTPUT_FILEPATH" &&
echo "Build succeeded: $OUTPUT_FILEPATH" ||
(echo "Build failed: $OUTPUT_FILEPATH" && exit 1)
