#!/bin/bash
# $1: test name (module name)

if [[ $# -lt 1 ]] ; then
    echo 'test.sh takes 1 params:
    $1: test name'
    exit 1
fi

TEST_FILEPATH="build/test$1.p8"

# clean up existing file (p8tool doesn't support parsing file with non-ascii chars, even just to replace appropriate blocks)
rm -f "$TEST_FILEPATH"

mkdir -p build
# I replaced $(pwd)/?.lua with $(pwd)/src/?.lua so I am forced to write the same exact package names as in the src files
# instead of src/{package}. This avoids having duplicate package contents on build, which would prevent correct overriding
# of package variables values just after the require line, such as debug_level.
# See remarks on require on https://github.com/dansanderson/picotool
p8tool build --lua "tests/test$1.lua" "$TEST_FILEPATH" --lua-path="$(pwd)/tests/?.lua;$(pwd)/src/?.lua" &&
# if a runtime error occurs during the test, exec bash will allow us to keep the terminal open to see it
gnome-terminal -x bash -x -c "pico8 -run -x \"$TEST_FILEPATH\" | pico-test; exec bash;" &&
# gnome-terminal -x bash -x -c "pico8 -run -x \"$TEST_FILEPATH\"; exec bash;" &&
echo "Running $TEST_FILEPATH"
