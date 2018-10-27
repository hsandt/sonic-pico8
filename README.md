master
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=master)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/master/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

develop
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=develop)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/develop/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

# Sonic PICO-8

A partial clone of classic Sonic the Hedgehog games made with PICO-8

## Progress

Version: 2.1

Features:

* Character runs on flat ground and slopes
* Character is blocked by walls when running
* Characters jumps with variable height (no head collision, buggy wall collision)

## Build dependency

### picotool

A build pipeline for PICO-8 ([GitHub](https://github.com/dansanderson/picotool))

The build script (`build.sh`) only works on Unix platforms.

### Sublime Text

Sublime Text 3 is not required but it can be convenient to run the build commands described in .sublime-project.

## Test dependency

### Lua 5.3

Tests run under Lua 5.3, although Lua 5.2 should also have the needed features (in particular the bit32 module).

### busted

A Lua unit test framework ([GitHub](https://github.com/Olivine-Labs/busted))

The test script (`test.sh`) only works on Linux (it uses gnome-terminal).

## Build pipeline

The .sublime-project file contains the most used commands for building the game. If you don't use Sublime Text, you can still use the commands described in a terminal or transfer them to the project configuration of your favorite code editor.

### Build and run

The most straightforward way to build and run the game on Unix platforms is:

* cd path/to/sonic-pico8-repo
* ./build.sh main game
* pico8 -run build/game.p8

### Build and test

To test the modules:

* cd path/to/sonic-pico8-repo
* ./test.sh all

### New project

If you use the scripts of this project to create a new game, in order to use build command *p8tool: edit data* you need to create a pico8 file at data/data.p8 first. To do this, open PICO-8, type *save data*, then copy the boilerplate file to data/data.p8.

## Runtime third-party libraries

### PICO8-WTK

[PICO8-WTK](https://github.com/Saffith/PICO8-WTK) has been integrated as a submodule. I use my own fork with a special branch [cleam\n-lua](https://github.com/hsandt/PICO8-WTK/tree/clean-lua), itself derived from the branch [p8tool](https://github.com/hsandt/PICO8-WTK/tree/p8tool).

* Branch `p8tool` is dedicated to p8tool integration. It exports variables instead of defining global variables to fit the require pattern.

* Branch `clean-lua` is dedicated to replacing PICO-8 preprocessed expressions like `+=` and `if (...)` with vanilla Lua equivalents. Unfortunately we need this to use external testing libraries running directly on Lua 5.3.

## Test third-party libraries

### gamax92/picolove's pico8 API

pico8api.lua contains vanilla lua equivalents or placeholders for PICO-8 functions. They are necessary to test modules from *busted* which runs under vanilla lua. The file is heavily based on gamax92/picolove's [api.lua](https://github.com/gamax92/picolove/blob/master/api.lua) and [main.lua](https://github.com/gamax92/picolove/blob/master/main.lua) (for the `pico8` table), with the following changes:

* Removed console commands (ls, cd, etc.)
* Removed unused functions
* Removed wrapping in api table to import functions globally (except for print)
* Remove implementation for LOVE 2D
* Adapted to Lua 5.3 instead of LuaJIT (uses bit32 module)

Low-level functions have the same behavior as in PICO-8 (add, del, etc.), whereas rendering functions only simulate the behavior by changing the `pico8` table's state (camera, clip, etc.). Pixels rendered on screen are not simulated though, so the actual effect of rendering cannot be tested.

## License

### Code

See LICENSE.md for the main code

The PICO8-WTK submodule contains its own license.

picolove and gamax92's fork are under zlib license.

### Assets

Most assets are derivative works of Sonic the Hedgehog, SEGA, especially the Master System and Mega Drive games. They have been created, either manually or with a conversion tool, for demonstration purpose. BGMs have been converted from Master System midi rips to PICO-8 format with [midi2pico](https://github.com/gamax92/midi2pico). I only retain copyright for the manual work of adaptation.

Assets that are not derivative works are under CC BY 4.0.
