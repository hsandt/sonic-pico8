#!/bin/bash
mkdir -p build
# need to pass PICO8_LUA_PATH explicitly into --lua-path option or path is set to None
# I replaced $(pwd)/?.lua with $(pwd)/src/?.lua so I am forced to write the same exact package names as in the src files
# instead of src/{package}. This avoids having duplicate package contents on build, which would prevent correct overriding
# of package variables values just after the require line, such as debug_level
# See remarks on require on https://github.com/dansanderson/picotool
p8tool build --lua "tests/test$1.lua" "build/test$1.p8" --lua-path="?.lua;$(pwd)/src/?.lua" &&
# if a runtime error occurs during the test, exec bash will allow us to keep the terminal open to see it
gnome-terminal -x bash -x -c "pico8 -run -x build/test$1.p8 | pico-test; exec bash;"
