#!/bin/bash
# Build the game from a main source file to an output file
# $1: source file (from src/, no .lua extension)
# $2: output file (from build/, no .p8 extension)
# $3: config ('debug' or 'release')

# check that source and output paths have been provided
if [[ $# -lt 3 ]] ; then
    echo "build.sh takes 3 params, provided $#:
    \$1: source file (from src/, no .lua extension)
    \$2: output file (from build/, no .p8 extension)
    \$3: config ('debug' or 'release')"
    exit 1
fi

OUTPUT_FILEPATH="build/$2.p8"

if [[ $2 == *..* ]]; then
	echo "$0: build path is unsafe: '$2'"
	exit 1
fi

echo "Building $1 -> $2 ($3)"

# clean up existing file (p8tool doesn't support parsing file with non-ascii chars, even just to replace appropriate blocks)
rm -f "$OUTPUT_FILEPATH"

# Pre-build
# 1. Copy all the source files to an intermediate/$config folder
# 2. Apply preprocessing directives to strip code unused in the current build config
echo "Pre-build..."
prebuild/copy_source_folder.sh src "intermediate/$3" &&
python3.6 prebuild/preprocess.py "intermediate/$3" "$3" &&
python3.6 prebuild/replace_strings.py "intermediate/$3"

if [[ $? -ne 0 ]]
then
    echo "Pre-build step failed, STOP."
    exit 1
fi

# Build
# 1. Copy metadata.p8 to future built file path because it's currently the only way p8tool can obtain the title, author and label
# 2. Build the game from the different modules in intermediate/$config folder
mkdir -p build
# copying metadata for mere p8 (not png) is still useful because __label__ will be preserved on overwriting build
# you'll still need to re-add game title and author manually in the
cp data/metadata.p8 "${OUTPUT_FILEPATH}"
# uncomment this when p8tool png build is fixed (https://github.com/dansanderson/picotool/issues/45)
# cp data/metadata.p8.png "${OUTPUT_FILEPATH}.png"

echo "Build..."
# ${@:4} will pass remaining args after the first 3
p8tool build --lua "intermediate/$3/game/$1.lua" --lua-path="$(pwd)/intermediate/$3/?.lua" --gfx "data/data.p8" --gff "data/data.p8" --map "data/data.p8" --sfx "data/data.p8" --music "data/data.p8" "$OUTPUT_FILEPATH" "${@:4}"
# uncomment this when p8tool png build is fixed (https://github.com/dansanderson/picotool/issues/45)
# p8tool build --lua "intermediate/$3/game/$1.lua" --lua-path="$(pwd)/intermediate/$3/?.lua" --gfx "data/data.p8" --gff "data/data.p8" --map "data/data.p8" --sfx "data/data.p8" --music "data/data.p8" "${OUTPUT_FILEPATH}.png" "${@:4}"


if [[ $? -ne 0 ]]
then
    echo "Build step failed, STOP."
    exit 1
fi

# Post-build:
# 1. Add game title and author at the top of source code for .p8.png
# 2. Add __label__ section from separate file for .p8.png (to make up for the lack of --label option in p8tool)
# 3. Replace special and api strings
echo "Post-build..."
# Don't use add_label_info in add_metadata.py as we have already copied metadata.p8 to reuse its label
python3.6 postbuild/add_metadata.py "$OUTPUT_FILEPATH" "-" "sonic pico-8" "hsandt" &&

if [[ $? -ne 0 ]]
then
	echo "Post-build failed, STOP."
	exit 1
else
	echo "Build succeeded: $OUTPUT_FILEPATH"
	exit 0
fi
