#!/bin/bash

# clean up existing file (p8tool doesn't support parsing file with non-ascii chars, even just to replace appropriate blocks)
rm -f "build/test$1.p8"

mkdir -p build
# I replaced $(pwd)/?.lua with $(pwd)/src/?.lua so I am forced to write the same exact package names as in the src files
# instead of src/{package}. This avoids having duplicate package contents on build, which would prevent correct overriding
# of package variables values just after the require line, such as debug_level.
# See remarks on require on https://github.com/dansanderson/picotool
p8tool build --lua "tests/test$1.lua" "build/test$1.p8" --lua-path="?.lua;$(pwd)/src/?.lua" &&
# replace non-ascii glyphs from special codes
python3.6 postbuild/replace_glyphs.py "build/test$1.p8" &&
# if a runtime error occurs during the test, exec bash will allow us to keep the terminal open to see it
gnome-terminal -x bash -x -c "pico8 -run -x build/test$1.p8 | pico-test; exec bash;"
