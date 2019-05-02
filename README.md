master
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=master)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/master/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

develop
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=develop)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/develop/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

# Sonic PICO-8

A partial clone of classic Sonic the Hedgehog games made with PICO-8

## Features

Version: 2.3

### Physics

* Character runs on flat ground and slopes
* Character is blocked by walls when running, walls and ceiling when jumping
* Character jumps with variable height

### Rendering

* Character rendered with Idle and Spin static sprite, Run animated sprite
* Environment rendered with tilemap

## Build

### Supported platforms

Only Linux Ubuntu (and supposedly the Debian family) is fully supported to build the game from sources. Other Linux distributions and UNIX platforms should be able to run most scripts, providing the right tools are installed, but a few references like `gnome-terminal` in `run.sh` would require adaptation.

Development environments for Windows such as MinGW and Cygwin have not been tested.

### Build dependencies

#### Python 3.6

Prebuild and postbuild scripts are written in Python 3 and use 3.6 features such as formatted strings.

#### picotool

A build pipeline for PICO-8 ([GitHub](https://github.com/dansanderson/picotool))

#### luamin

A Lua minifier ([luamin](https://github.com/mathiasbynens/luamin))

You don't need to install it globally, instead you can:

* `cd npm`
* `npm update`

It will install `luamin` (along with `luaparse`), which is used in `npm/luamin_file`, itself used inside `build.sh`. `luamin_file` is just a stripped down version of the `luamin` script, which only takes a file path argument, and behaves as if the input always came from a TTY, which avoids stalling while building from a non-terminal environment such as a Sublime Text build system (it's a hack).

### Build and run

First, make sure the `pico8` executable is in your path.

The most straightforward way to build and run the game on Unix platforms is:

* `cd path/to/sonic-pico8-repo`
* `./build.sh main release`
* `./run.sh main release`

Instead of the last instruction, you can also enter directly:

* `pico8 -run build/sonic-pico8_v${BUILD_VERSION}_release.p8`

where BUILD_VERSION is set in `sonic-2d-tech-demo.sublime-project` as well as `.travis.yml`.

`sonic-2d-tech-demo.sublime-project` contains the most used commands for building the game. If you don't use Sublime Text, you won't be able to run the commands directly, but you can use them directly in a terminal, or copy-paste them to the project configuration of your favorite code editor.

All the build and run commands are usage variants around the script `build.sh` and `run.sh`. `build.sh` relies on picotool as well as custom shell and Python scripts in the `prebuild` and `postbuild` folders.

`build.sh` can take a build configuration as 2nd argument. The complete list of configurations is listed in `sonic-2d-tech-demo.sublime-project` and `prebuild/preprocess.py`. The config of biggest output size is `build` (generally it has too many tokens to even fit in a cartridge), while the config of smallest output size is `release`, and is used to release the final game cartridge.

Finally, `build.sh` takes a file base name as 1st argument. To build the game, passing `main` is enough, but to build rendered integration tests, you need to pass the name of the test, such as `itestplayercharacter`.

## Test

## Supported platforms

* Unit tests and headless integration tests are run directly in Lua, making them cross-platform.

* Rendered integration tests are run with PICO-8, on special builds dedicated to testing. Therefore, a build step is required, which is only possible on UNIX platforms.

### Test dependencies

#### Lua 5.3

Tests run under Lua 5.3, although Lua 5.2 should also have the needed features (in particular the bit32 module).

#### busted

A Lua unit test framework ([GitHub](https://github.com/Olivine-Labs/busted))

The test script (`test.sh`) only works on Linux (it uses gnome-terminal).

### Run unit tests and headless integration tests

To test the modules:

* `cd path/to/sonic-pico8-repo`
* `./test.sh all` or `./test.sh all all` if you want to include `#mute` tests (longer)

This will run all the unit tests, as well as headless integration tests. To only run the latter type, use `./test.sh headless_itests`.

I try to aim for 100% test coverage before pushing but you can always verify the Travis and CodeCov badges at the top of this README.

### Run rendered integration tests

Those tests need to be built with picotool and run with PICO-8. We recommend the itest_light config, which has no visual logging but increases the odds to have a build that fits into a cartridge. For example:

* `cd path/to/sonic-pico8-repo`
* `./build.sh itestplayercharacter itest_light`
* `./run.sh itestplayercharacter itest_light`

## Modding

You can modify the spritesheet used in the build pipeline by running the custom Sublime Text build command `p8tool: edit data`, or in the shell: `pico8 -run data/data.p8`.

This will open the cartridge `data.p8` in PICO-8. This cartridge contains only assets, and no code at all. Make your changes, save the cartridge, then build the project to see your result.

For fast iterations, you can also directly modify assets while running the built game, but remember your changes are temporary and will be overwritten by the next build. To preserve your changes, you must save the cartridge, open it and copy the data parts (`__gfx__`, `__gff__`, `__map__`, `__sfx__` and `__music__`) and replace them in `data.p8` manually.

Alternatively, to edit the spritesheet in your favorite editor:

1. Export it from PICO-8 with the PICO-8 command `export spritesheet.png`
2. Edit it in your favorite editor
3. Import it back to PICO-8 with the PICO-8 command `import spritesheet.png`

## New project

If you use the scripts of this project to create a new game, in order to use build command `p8tool: edit data` you need to create a pico8 file at data/data.p8 first. To do this, open PICO-8, type `save data`, then copy the boilerplate file to data/data.p8.

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

## References

* Classic Sonic games (Sonic the Hedgehog, Sonic the Hedgehog 2, Sonic the Hedgehog 3 & Knuckles)
* [Sonic Physics Guide](http://info.sonicretro.org/Sonic_Physics_Guide)
* [TASVideos Resources for Sonic the Hedgehog](http://tasvideos.org/GameResources/Genesis/SonicTheHedgehog.html)

## License

### Code

The LICENSE file at the root applies to the main code.

The PICO8-WTK submodule contains its own license.

The original picolove and gamax92's fork are under zlib license.

The `npm` folder has its own MIT license because I adapted a script from the `luamin` package. After installing npm packages, you will also see package-specific licenses in `node_modules`.

### Assets

Most assets are derivative works of Sonic the Hedgehog (SEGA), especially the Master System and Mega Drive games. They have been created, either manually or with a conversion tool, for demonstration purpose. BGMs have been converted from Master System midi rips to PICO-8 format with [midi2pico](https://github.com/gamax92/midi2pico), an automated music format converter.

SEGA owns the Sonic the Hedgehog trademark and retains all copyrights on the original assets.

I only retain copyright for the manual work of adaptation (i.e. pixel art, but not music).

Assets that are not derivative works are under CC BY 4.0.
