#!/bin/bash
# Build a .p8 file from a main source file corresponding to the representative file
# $1: representative file base name (used to deduce the main lua script and the output path)
# $2: config ('debug' or 'release')"
# Options:
#   -m    --no-minify    do not apply minification step

# check that source and output paths have been provided
if [[ $# -lt 2 ]] ; then
    echo "build.sh takes 2 params, provided $#:
    \$1: representative file base name (used to deduce the main source file and the output path)
    \$2: config ('debug' or 'release')"
    exit 1
fi

# store arguments with explicit names before shifting
file_basename=$1
config=$2

# shift arguments 2 positions so we start reading options at $1
shift 2

minify=true

while [ "$1" != "" ]; do
    case $1 in
        -m | --no-minify )           shift
                                minify=false
                                ;;
        * )                     echo "unknown option: $1"
                                exit 1
    esac
    shift
done

echo "> $0 $file_basename $config minify: $minify"

. helper/config_helper.sh

# will define: MAIN_SOURCE_BASENAME, OUTPUT_BASENAME, REPLACE_ARG_SUBSTITUTES, ITEST (optional)
define_build_vars "$file_basename"

if [[ $? -ne 0 ]]; then
    echo "define_build_vars failed, STOP."
    exit 1
fi

. helper/path_helper.sh

if is_unsafe_path "$OUTPUT_BASENAME"; then
    echo "$0: build path is unsafe: '$OUTPUT_BASENAME'"
    exit 1
fi

INTERMEDIATE_MAIN_SOURCE_FILEPATH="intermediate/${config}/game/${MAIN_SOURCE_BASENAME}.lua"
OUTPUT_FILEPATH="build/${OUTPUT_BASENAME}_${config}.p8"

echo "Building 'src/game/${MAIN_SOURCE_BASENAME}.lua' -> '$OUTPUT_FILEPATH' (${config})"

# clean up existing file (p8tool doesn't support parsing file with non-ascii chars, even just to replace appropriate blocks)
rm -f "$OUTPUT_FILEPATH"

# Pre-build
# 1. Copy all the source files to an intermediate/$config folder
# 2. Apply preprocessing directives to strip code unused in the current build config
# 3. Apply lua minification to reduce character count
echo "Pre-build..."
prebuild/copy_source_folder.sh src "intermediate/${config}" &&
python3.6 prebuild/preprocess.py "intermediate/${config}" "$config" &&
python3.6 prebuild/replace_strings.py "intermediate/${config}" $REPLACE_ARG_SUBSTITUTES

if [[ $? -ne 0 ]]; then
    echo "Pre-build step failed, STOP."
    exit 1
fi

# Build
# 1. Copy metadata.p8 to future built file path because it's currently the only way p8tool can obtain the label (title and author will be lost, and re-added in postbuild anyway)
# 2. Build the game from the different modules in intermediate/$config folder
mkdir -p build
# copying metadata for mere p8 (not png) is still useful because __label__ will be preserved on overwriting build
# you'll still need to re-add game title and author manually in the
cp data/metadata.p8 "$OUTPUT_FILEPATH"
# uncomment this when p8tool png build is fixed (https://github.com/dansanderson/picotool/issues/45)
# cp data/metadata.p8.png "${OUTPUT_FILEPATH}.png"

echo "Build..."
# ${@:3} will pass remaining args after the first 2
BUILD_COMMAND="p8tool build --lua \"$INTERMEDIATE_MAIN_SOURCE_FILEPATH\" --lua-path=\"$(pwd)/intermediate/${config}/?.lua\" --gfx data/data.p8 --gff data/data.p8 --map data/data.p8 --sfx data/data.p8 --music data/data.p8 \"$OUTPUT_FILEPATH\" ${@:3}"
# uncomment this when p8tool png build is fixed (https://github.com/dansanderson/picotool/issues/45)
echo "> $BUILD_COMMAND"
bash -c "$BUILD_COMMAND"

# p8tool png export is broken, export manually from pico8 to the different formats instead
# p8tool build --lua "intermediate/${config}/game/${file_basename}.lua" --lua-path="$(pwd)/intermediate/${config}/?.lua" --gfx "data/data.p8" --gff "data/data.p8" --map "data/data.p8" --sfx "data/data.p8" --music "data/data.p8" "${OUTPUT_FILEPATH}.png" "${@:3}"

if [[ $? -ne 0 ]]; then
    echo "Build step failed, STOP."
    exit 1
fi

# Post-build:
# 1. Minify lua code
# 2. Add game title and author at the top of source code for .p8.png
# 3. Add __label__ section from separate file for .p8.png (to make up for the lack of --label option in p8tool)
# 4. Replace special and api strings
echo "Post-build..."

if [[ "$minify" == true ]]; then
    python3.6 postbuild/minify.py "$OUTPUT_FILEPATH"

    if [[ $? -ne 0 ]]; then
        echo "Minification failed, STOP."
        exit 1
    fi
fi

# Don't use add_label_info in add_metadata.py as we have already copied metadata.p8 to reuse its label, so pass "-"
python3.6 postbuild/add_metadata.py "$OUTPUT_FILEPATH" "-" "sonic pico-8" "hsandt" &&

if [[ $? -ne 0 ]]
then
	echo "Add metadata failed, STOP."
	exit 1
else
	echo "Build succeeded: $OUTPUT_FILEPATH"
    # Clean intermediate folder now. If the build failed, the intermediate folder will remain for debugging.
    # rm -rf "intermediate/${config}"
	exit 0
fi
