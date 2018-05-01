#!/bin/bash
mkdir -p build
# need to pass PICO8_LUA_PATH explicitly into --lua-path option or path is set to None
p8tool build --lua "tests/test$1.lua" "build/test$1.p8" --lua-path="?;?.lua;$(pwd)/?.lua" &&
# if a runtime error occurs during the test, exec bash will allow us to keep the terminal open to see it
gnome-terminal -x bash -x -c "pico8 -run -x build/test$1.p8 | pico-test; exec bash;"
