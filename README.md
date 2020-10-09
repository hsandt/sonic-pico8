master
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=master)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/master/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

develop
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=develop)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/develop/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

# PICO-Sonic

A partial clone of classic Sonic the Hedgehog games made with PICO-8. It is inspired by the 16-bit games for mechanics, and by a mix of the 8-bit and 16-bit games for graphics and audio.

This is a fan game distributed for free and is not endorsed by Sega Games Co., Ltd, which owns the Sonic the Hedgehog trademark and retains all copyrights on the original assets.

It is currently under development.

## Compatibility

Works with PICO-8 0.2.0i and 0.2.1b.

## Screenshots

![Sonic running toward emerald](screenshots/picosonic_showcase.png?raw=true)

## Features

Version: 4.2

### Physics

* Character runs on flat ground, slopes, and through loops
* Character is blocked by walls when running, walls and ceiling when jumping
* Character jumps with variable height orthogonally to current ground
* Character preserves momentum on jumping and landing
* Spring bounce

### Rendering

* Character sprites: *idle*, *walk* cycle, *run* cycle, *spin* cycle
* Foreground plane: grass and leaves, loop entrance
* Midground plane: general collision tiles, loop exit, some decorations
* Background planes: sky, ocean and trees moving with parallax
* Camera window and smoothing system

### Audio

* Stage BGM and jump SFX

### Content

One demo stage, a reproduction of the first part of Angel Island Act 1 (before it is set on fire) at scale 1:1 (but using tiles of 8x8) thanks to a custom map streaming system. There are no enemies, hazards, rings nor item boxes, but some items have been replaced with emeralds that can be collected.

## Known technical issues

* When jumping diagonally, Sonic can go past the ceiling in a vertical motion
* Sonic can walk up low slopes with too much ease, and some slopes behave differently than in Sonic 3
* After running up a vertical wall and falling, Sonic may fall *into* the wall and get stuck
* The game slows down in some areas, and tends to run at 30 FPS (instead of 60) in others

## Known design issues

* The stage feels very empty and too big due to the lack of items and hazards, despite a reproduction 1:1 of the original map
* Scaling is slightly inconsistent as the tilemap is 1:1, but the Sonic sprites are slightly smaller than they should be, and the rocks even smaller

## Releases

You can directly download a released version of the game on the [releases](Releases) page. If you download the binary export for your platform, you're good to go.

However, if you download the cartridges or compressed cartridges (png) archive to run them directly in PICO-8, there are a few caveats:

1. This game uses multiple cartridges, therefore you need to unzip the archive in your local PICO-8 *carts* folder so it can properly detect and load neighbor cartridges on game state transition (if you only want to play the core game and without title menu, you can just run picosonic_ingame.p8 anywhere, but note that it will freeze when the stage has been finished)

2. The ingame cartridge (in .p8 or .p8.png form) cannot be run with a vanilla PICO-8 as it exceeds the maximum token limit (8192). To play it, you need to patch your PICO-8 executable by following the procedure I described in [this thread](https://www.lexaloffle.com/bbs/?pid=71689#p).

3. I recommend using a fast reload patch (I will write a post to explain how to do it later) to instantly stream stage data. Otherwise, the game will pause half a second every time the character is approaching a different 128x32-tiles region of the map, and also in the transition area between two regions.

## Build

Follow this if you want to build the game yourself.

Soon, you will be able to choose between building the debug or the release version.

### Supported platforms

Mostly UNIX, and specifically Linux for some scripts.

See Supported platforms in [pico-boots](https://github.com/hsandt/pico-boots) README for more information.

### Build dependencies

See *Build dependencies* in [pico-boots](https://github.com/hsandt/pico-boots) README.

### Build and run

First, make sure the `pico8` executable is in your path.

The most straightforward way to build and run the game on Unix platforms is:

* `cd path/to/sonic-pico8-repo`
* `./build_game.sh`
* `./run_game_debug.sh`

Instead of the last instruction, you can also enter directly:
* `pico8 -run build/picosonic_v${BUILD_VERSION}_debug.p8`

where BUILD_VERSION is set in `sonic-2d-tech-demo.sublime-project` as well as `.travis.yml`.

To play the release version (no debugging features, but more compact code and more likely to fit into a PICO-8 cartridge):

* `cd path/to/sonic-pico8-repo`
* `./build_and_install_all_cartridges.sh` release
* `./run_cartridge.sh titlemenu release`

This will build and install all cartridges into the PICO-8 *carts* folder, then run the entry cartridge (`titlemenu`) from there. Replace `titlemenu` with `ingame` to directly start in the Angel Island stage.

As explained in the *Releases* section, playing the game in the *carts* folders is required because the project uses multiple cartridges, and PICO-8 can only load appendix cartridges from there.

### Run integration tests

Integration tests consists in game simulations in predetermined scenarios, and are therefore run directly in PICO-8. To build the integration test cartridge and run it:

* `cd path/to/pico-boots-demo`
* `./build_itest.sh`
* `./run_itest.sh`

### Custom build

`sonic-2d-tech-demo.sublime-project` contains the most used commands for building the game. If you don't use Sublime Text, you won't be able to run the commands directly, but you can still read this project file to understand how the scripts are used, and do the same in a terminal. You can also copy-paste the commands to the project configuration of your favorite code editor instead.

All the build and run commands revolve around the scripts `build_single_cartridge.sh` / `build_itest.sh` and `run_cartridge.sh` / `run_itest.sh`. Once you understand them, you can create your own build and run commands for your specific needs.

## Test

## Supported platforms

* Unit tests and headless integration tests are run directly in Lua, making them cross-platform.

* Rendered integration tests are run with PICO-8, on special builds dedicated to testing. Therefore, a build step is required, which is only possible on UNIX platforms.

### Test dependencies

See *Test dependencies* in [pico-boots](https://github.com/hsandt/pico-boots) README.

### Run unit tests and headless integration tests

To run all the (non-#mute) unit tests:

* `cd path/to/pico-boots-demo`
* `./test.sh`

I try to aim for 100% test coverage before pushing but you can always verify the Travis and CodeCov badges at the top of this README.

### Run rendered integration tests

Integration tests consists in actual game simulations in predetermined scenarios. Therefore, they are built with picotool and run directly in PICO-8. To build the integration test cartridge and run it:

* `cd path/to/sonic-pico8-demo`
* `./build_itest.sh`
* `./run_itest.sh`

## Modding

You can modify the spritesheet used in the build pipeline by running the custom Sublime Text build command `p8tool: edit data`, or in the shell: `pico8 -run data/data.p8`.

This will open the cartridge `data.p8` in PICO-8. This cartridge contains only assets, and no code at all. Make your changes, save the cartridge, then build the project to see your result.

For fast iterations, you can also directly modify assets while running the built game, but remember your changes are temporary and will be overwritten by the next build. To preserve your changes, you must save the cartridge, open it and copy the data parts (`__gfx__`, `__gff__`, `__map__`, `__sfx__` and `__music__`) and replace them in `data.p8` manually.

Alternatively, to edit the spritesheet in your favorite editor:

1. Export it from PICO-8 with the PICO-8 command `export spritesheet.png`
2. Edit it in your favorite editor
3. Import it back to PICO-8 with the PICO-8 command `import spritesheet.png`

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

Most assets are derivative works of Sonic the Hedgehog, especially the Master System and Mega Drive games. They have been created, either manually or with a conversion tool, for demonstration purpose. I drew the sprites based on the Mega Drive and GBA games, while the BGMs have been converted from Master System midi rips to PICO-8 format with [midi2pico](https://github.com/gamax92/midi2pico), an automated music format converter.

Assets that are not derivative works are under CC BY 4.0.
