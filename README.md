master
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=master)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/master/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

develop
[![Build Status](https://travis-ci.org/hsandt/sonic-pico8.svg?branch=develop)](https://travis-ci.org/hsandt/sonic-pico8)
[![codecov](https://codecov.io/gh/hsandt/sonic-pico8/branch/develop/graph/badge.svg)](https://codecov.io/gh/hsandt/sonic-pico8)

# pico sonic

[itch.io page](https://komehara.itch.io/pico-sonic)

*The 8 Pico Emeralds have been scattered! Sonic arrives on Pico Island, ready to collect them all!*

![The 8 Pico Emeralds displayed in circle, each color corresponding to a color on the PICO-8 logo](doc/all_emeralds.png?raw=true)

**pico sonic** is a partial demake of Sonic the Hedgehog 3 made with [PICO-8](https://www.lexaloffle.com/pico-8.php). It features a simplified version of Angel Island Act 1 with some tweaks. Various classic Sonic games were used as reference, including the 8-bit games (Game Gear and Master System), which have sprites closer to PICO-8's resolution and color palette, and the GBA titles, which have more clear-cut graphics.

The project was started as a personal challenge and was meant to be a fully-fledged fan game, but I eventually dropped many features to focus on Sonic's main movements and the exploration of the stage. Consider it a technical demo with some exploration challenge.

Disclaimer: the game runs on a patched version of PICO-8 that doesn't have the original token count limitation. However, I do respect the (compressed) characters limit for each cartridge. See [Releases](#releases) for more info.

pico sonic is a fan game distributed for free and is not endorsed by Sega. Sega Games Co., Ltd owns the Sonic the Hedgehog trademark and copyrights on the original assets.

## Screenshots

![Sonic running toward emerald](doc/picosonic_showcase.png?raw=true)

## Compatibility

Works with PICO-8 0.2.2.

## Features

Version: 6.2

### Physics

* Character can run on flat ground, slopes, and through loops with acceleration, deceleration and braking
* Character can roll from run
* Character is blocked by walls and ceiling
* Character falls from steep slopes and ceiling if running speed is too low
* Character can jump with variable height orthogonally to current ground
* Character preserves momentum on jumping and landing
* One-way platforms
* Spring bounce (vertical and horizontal)
* Spin dash

### Rendering

* Character sprites: *idle*, *walk* cycle, *run* cycle, *spin* cycle, *brake* animation, spring *jump*
* Foreground plane: grass and leaves, loop entrance
* Midground plane: general collision tiles, loop exit, some decorations
* Background planes: waterfalls, sky, ocean, trees and forest holes moving with parallax
* Camera window and smoothing system
* Custom camera forward extension system to show more elements ahead of Sonic when he runs fast or faces a direction for some time

### UI

* Title logo, animated background and menu
* Wait in front of title menu to start the attract mode
* Full cinematic before starting the stage
* Zone splash screen on stage start
* Ingame HUD: list of picked emeralds shown in top-left corner
* Result screen on stage clear
* Retry screen to restart stage keeping or dropping emeralds picked so far
* Fade-in/out effects using gradual color palette swapping

### Audio

* BGM: Sonic 3 Angel Island BGM demake
* Jingles: Sonic 3 intro, pick emerald, stage clear
* SFX: brake, roll, jump, spring jump, rotating goal plate, menu confirm

### Notable features missing

* Timer
* Looking up

### Notable physics differences

* Preservation of velocity when landing on slopes is more organic and uses vector projection, while the [SPG](https://info.sonicretro.org/SPG:Slope_Physics#Reacquisition_Of_The_Ground) denotes different formulas based on the slope angle and the relationship between horizontal and vertical speed. This is very perceptible when jumping on the first two slopes.
* It is possible to control horizontal acceleration after jumping out of a roll. This was considered to be a better user experience, and actually recommended by the Sonic Physics Guide despite being unlike the original games.
* Late jump: as in modern platforms, the character can jump up to 6 frames after falling off ground, for more permissive jumps from a platform ledge. This can be disabled in the Pause menu for a more "classic" experience.
* Collision check: character wall sensor is placed higher than in the original games, esp. when rolling, to allow hitting ground as a wall and stopping mid-loop when moving at high speed (e.g. after spin dash). In addition a second wall check is done after the initial wall and ground check if quadrant changed, as a way to verify if there is still a wall blocking in the new quadrant (and avoid being stuck when moving at high speed in loops, again).

### Notable camera differences

Because PICO-8 has a square view of 128x128 pixels, and the game is more about exploration than moving toward the right, camera was adjusted to make navgiation a little easier.

* Camera is fundamentally centered on X, but moves toward the direction Sonic is facing. When Sonic is running, camera moves even more forward to show what is ahead
* Spin dash lag is implemented by freezing then releasing the camera, instead of the more complex recording and playing of character positions during the start of the spin dash

### Notable sprite differences

* Sonic uses the "jump fall" sprite from Sonic CD/Mania as spring jump sprite (although it's not technically correct since it shouldn't be used for upward motion)

* I reversed the order the Brake sprites so it made more sense visually. Now, Sonic just plays a short 2-sprite brake animation when you start moving in the opposite direction of running. If you keep moving in the opposite direction, it shows the "reverse brake" sprite, which gives more the impression than Sonic is doing a complete turn and sprinting in the opposite direction.

## Content

There is a single demo stage which covers the first part of Angel Island Act 1. Scale is close to 1:1, but Sonic is slightly smaller (relatively to the environment) than in the original game.

The game uses a custom map "streaming" system to allow a bigger map than PICO-8's standard tilemap. There are no enemies, hazards, rings nor item boxes. Rocks are not destructible.

Some enemies have been replaced by static obstacles, and most importantly some items have been replaced by emeralds that can be collected to make the stage more interesting.

Stage gimmicks:

* Spring (vertical and horizontal)
* Loop
* Launch ramp

## Controls

You can play with keyboard or gamepad with those inputs:

| Keyboard                 | Gamepad                | Action                          |
|--------------------------|------------------------|---------------------------------|
| Left/right arrows        | D-pad left/right       | Move                            |
| Down arrow               | D-pad down             | Crouch, Roll (during run)       |
| Z/C/N                    | Face button up/down    | Jump, Spin Dash (during Crouch) |
| X/V/M                    | Face button left/right | Cancel (menu)                   |
| Enter                    | Start                  | Open pause menu                 |
| Alt+Enter                |                        | Toggle fullscreen               |
| Ctrl+R (standalone only) |                        | Restart current cartridge       |

If you gamepad mapping is not correct when playing with the native PC binaries, you can customize it with [SDL2 Gamepad Tool](https://www.generalarcade.com/gamepadtool) and copy-paste the configuration line into sdl_controllers.txt in PICO-8's [configuration directory](https://pico-8.fandom.com/wiki/Configuration). For instance, the Logicool Gamepad F310 had Open PICO-8 menu mapped to Right Trigger, so I remapped it to Start instead.

### Pause menu

In the pause menu (toggled with Enter/Start), if you are in-game, you can select the following options:

* Late jump: press left/right to toggle the Late jump feature ON/OFF (default: ON)
* Warp to start: restart stage from beginning keeping collected emeralds
* Retry from zero: restart stage losing emeralds collected so far
* Back to title: go back to title menu

## Known technical issues

* The player cannot control the character until the stage intro is over
* The game pauses to switch to another cartridge, esp. at the end of the stage intro (only memory reload has been patched on PICO-8 to be instant)
* Web version: high-pitched sounds in BGM do not convey the same as in desktop/cartridge versions

## Known design issues

* The stage feels a bit empty and too big due to the lack of items, enemies and hazards
* Scaling is slightly inconsistent as the tilemap is 1:1, but the Sonic sprites are slightly smaller than they should be (rocks in particular look very big)
* Some ugly sprite / sprite transitions and SFX too far from the original sounds

## Releases

You can directly download a released version of the game on the [releases](https://github.com/hsandt/sonic-pico8/releases) page, or on the [itch.io page](https://komehara.itch.io/pico-sonic). If you download the binary export for your platform, you're good to go.

However, if you download the cartridges or compressed cartridges (png) archive to run them directly in PICO-8, there are a few caveats:

1. This game uses multiple cartridges, therefore you need to unzip the archive in your local PICO-8 *carts* folder so it can properly detect and load neighbor cartridges on game state transition (if you only want to play the core game and without title menu, you can just run picosonic_ingame.p8 anywhere, but note that it will freeze when the stage has been finished)

2. The ingame cartridge (in .p8 or .p8.png form) cannot be run with a vanilla PICO-8 as it exceeds the maximum token limit (8192). To play it, you need to patch your PICO-8 executable to support more tokens, by either following the procedure I described in [this thread](https://www.lexaloffle.com/bbs/?pid=71689#p) or applying the patches provided in [pico-boots/scripts/patches](https://github.com/hsandt/pico-boots/tree/develop/scripts/patches) (currently only provided for Linux, OSX and Windows runtime binaries; I will try to push patches for the editor, which you are probably using if you own PICO-8). You will need xdelta3 to apply the patches.

3. I also recommend using a fast reload patch to instantly stream stage data. Otherwise, the game will pause half a second every time the character is approaching a different 128x32-tiles region of the map, and also in the transition area between two regions. Similarly to 2., you should apply the patch from the patches folder using xdelta3 (editor patches not available yet).

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
* `./build_and_install_all_cartridges.sh [config]`
* `./run_cartridge.sh titlemenu [config]`

This will build and install all cartridges into the PICO-8 *carts* folder, with the passed config (debug by default), then run the entry cartridge (`titlemenu`). The cartridges are installed in *carts/picosonic/v\[version]\_\[config]*. Replace `titlemenu` with `ingame` to directly start in the Pico Island stage.

For instance, to play the release version (no debugging features, but more compact and faster):

* `cd path/to/sonic-pico8-repo`
* `./build_and_install_all_cartridges.sh release`
* `./run_cartridge.sh titlemenu release`

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

## Tools and process

* Tilemap and audio editing made with PICO-8
* Sprites made with Aseprite
* Code written with Sublime Text

I used my own PICO-8 framework, [pico-boots](https://github.com/hsandt/pico-boots).

#### Audio

For the BGMs, I used 8-bit remixes of Sonic 3 & Knuckles by danooct1 with the author's permission. I had to go from 8 channels to only 3 or 4 (PICO-8 has 4 channels but during in-game I need to keep one channel for SFX) by picking the notes I considered the most important.

Then I exported the modified FamiTracker Music (FTM) files to MIDI, and converted each MIDI channel to PICO-8 format using [midi2pico](https://github.com/gamax92/midi2pico). Finally, I merged the channels manually and reworked some notes to make them sound better in PICO-8.

For the SFX, I listened to the original ones, sometimes used Audacity to inspect wave forms, and tried to reproduce them from scratch with PICO-8's sound editor.

## Credits

* Sonic Team - Original games
* danooct1 - 8-bit remixes of Sonic 3 BGMs
* Leyn (komehara) - Programming, Sprite/SFX/jingle adaptation, BGM adjustments

## License

### Code

The LICENSE file at the root applies to the main code.

The PICO8-WTK submodule contains its own license.

The original picolove and gamax92's fork are under zlib license.

The `npm` folder has its own MIT license because I adapted a script from the `luamin` package. After installing npm packages, you will also see package-specific licenses in `node_modules`.

### Assets

Sega Games Co., Ltd owns the Sonic the Hedgehog trademark and copyrights on the original assets.

Most assets are derivative works of classic Sonic the Hedgehog games. They have been made with a combination or automated conversion and manual work (depending on the asset's complexity).

Because of this, I only consider original assets and the manual work of adaptation to be under CC BY NC 4.0.
