#!/bin/bash

# clean up existing file (p8tool doesn't support parsing file with non-ascii chars, even just to replace appropriate blocks)
rm -f "build/game.p8"

mkdir -p build
# build the game from the different modules
p8tool build --lua "src/main.lua" --lua-path="?.lua;$(pwd)/src/?.lua" --gfx "data/data.p8" --gff "data/data.p8" --map "data/data.p8" --sfx "data/data.p8" --music "data/data.p8" "build/game.p8" &&
# replace non-ascii glyphs from special codes
python3.6 postbuild/replace_glyphs.py "build/game.p8" &&
echo "Build succeeded: build/game.p8" ||
(echo "Build failed: build/game.p8" && exit 1)
