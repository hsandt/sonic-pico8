# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0] - 2020-12-10
### Added
- Title: added title background showing "Pico Island" with water shimmer animation, pico-sonic logo, Sonic 3 (not 3 & Knuckles) intro jingle, and title menu showing after a short time
- Title: added stylized menu cursor, and confirm SFX (title uses Sonic 3 shoe, credits use Sonic 2 emblem as cursor)
- Splash screen: added zone splash overlay on stage start (Sonic 3 style)
- System: added "Back to title" menuitem to ingame phase
- Character: added roll (physics, animation, SFX): characters spins on the ground when pressing down while running. Physics is similar to original game, with more freedom (low friction, no clamping)
- Character physics: increased center height compact by 2, full height compact by 4 to match new, bigger spin sprites
- Character sprite: added brake (animation, SFX). Animation is similar to original game but swapped sprite order for better look
- Character sprite: added handmade 45-degree-rotated sprites to replace ugly computed rotated sprites on slopes
- Camera: gradually move camera forward when character is running fast to show more things ahead (forward extension system)
- Camera: gradually move camera forward when character facing a direction for a certain time
- Camera: clamps camera to different bottom limit defined in stage data, to match Sonic 3's dynamic camera limit
- HUD: display picked emeralds at top-left of screen, unpicked emeralds as silhouettes
- Background: completed forest bottom with holes, light shafts and dark green dithered texture
- SFX: added pick emerald star FX
- Audio: added 8-bit version of Angel Island BGM
- Audio: added pick emerald jingle (BGM volume is halved while it's played). It covers other SFX
- Audio: added spring jump SFX
- Tilemap: added regions 30 and 31 to place new goal plate
- Tilemap: added palm tree tiles (leaves are generated on stage loading)
- Tilemap: added launch ramp similar to the one in the original Angel Island. It sends the character diagonally with a speed multiplier, if arriving at certain speed
- Tilemap: added platform to reach spring that leads to upper level at the beginning
- Tilemap: added platforms in region (1, 1) to replace the grabbable ropes of the original game
- Tilemap: added platform in region (2, 1) to simulate log falling in waterfall of the original game
- Goal: when Sonic goes through the goal plate, it plays a rotation animation and Sonic is forced to move right and leave the screen
- Stage clear: added stage clear sequence after reaching goal, in its own cartridge. The result screen shows with graphics translations, including picked emeralds, and the stage clear jingle is played

### Changed
- Character physics: do not clamp ground speed nor air velocity X if already running/flying at higher speed
- Character physics: fixed hop (shortest jump)
- Character physics: fixed diagonal jump going through ceiling corner
- Character physics: fixed character landing into wall when angle is slightly lower than 90 degrees
- Character sprite: streamlined spin anim to a single animation (also used for rolling, but at higher speed)
- Character sprite: changed walk sprites pivot to make Sonic move ahead a bit during the animation
- Slope: fixed slope orientation for mid slopes causing Sonic to run them up too easily
- Slope: adjusted mid-slope to lower slope angle for better feel (closer to Sonic 3 Angel Island)
- Tilemap: fixed missing grass tiles at the beginning
- Tilemap: fixed incorrect tiles at the edge of some regions
- Tilemap: fixed last loop
- Tilemap: rearranged loops to provide extra momentum at the end
- Tilemap: replaced rock hiding spring in Sonic 3 with just a spring
- Tilemap: made emerald 2 accessible via a hidden passage from the right
- Tilemap: higher ceiling in region (0, 0) to avoid hitting it with the 3rd spring
- Sprite: made bigger rocks
- Meta: changed author name to Leyn

## [4.2] - 2020-09-27
### Added
- Tilemap: switch to extended map system. Angel Island is now split is 3x2 regions of 128x32 tiles, defined in separate PICO-8 cartrdiges and reloaded into memory at runtime when approaching those regions. When close to 2-4 regions, an transition region is created from 2-4 patches of existing map data. Item collision and render also support this new system.
- Tilemap: redrew extended map with 6 regions with complete skinning, except for palm trees
- Loop: external loop triggers allow to setup correct collision layer *before* entering loop
- Animation: added 4 sprites to spin cycle
- Camera: camera window and smooth motion depending on character grounded/airborne state

### Changed
- Animation: better walk cycle with 6 sprites
- Tilemap: draw loop entrance on foreground by drawing on-screen sprites manually
- Tilemap: removed loop flags, now loop triggers are defined in stage data
- Tile: fixed spring animation when landing on right part
- Tile: fixed loop collision data
- Export: fixed export icon

## [4.1] - 2020-09-21
### Added
- Spring tile and behavior
- Emerald tile and behavior
- Detail tiles: falling leaves, hiding leaves
- Animation: character run cycle when moving on ground at high speed
- Jump SFX (takes over less important music channel)
- Credits screen

### Changed
- Split project in two cartridges: titlemenu and ingame (to drop compressed size under 100% and allow export again)
- Reorganized spritesheet and collision data
- Skinned level completely, improved shapes, added ceiling, springs and emeralds
- Render foreground after midground (grass and leaves)

## [4.0] - 2020-09-10
### Added
- Character falls off wall or ceiling when running too slow
- Character sprite rotates gradually to be upward when airborne
- Character cannot intentionally move after losing ground (horizontal control lock)
- Stripped version of Angel Island Act 1 (replaces proto zone), skinning WIP
- Camera stops at stage boundaries
- Character cannot go past the left edge of the stage
- Ground tile detection system applied to loop: loop collision layer system allows character to run through it. Does not support going through loop twice in the same direction
- Background: sky, sea with light reflections, trees and leaves with parallax

### Changed
- Updated pico-boots to v1.0
- Snap character sprite angle to closest 45-degree step (closer to Sonic 1\~3 than Sonic Mania)
- Moved goal to stage right boundary
- Character spawns on ground on stage start
- Fixed air spin sprite angle being affected by previous rotation on ground
- Fixed pixel jitter when running on ceiling
- Fixed character landing inside slope
- Fixed character landing 1px above the ground
- Fixed collision mask on loop tiles

## [3.2] - 2020-08-25
### Added
- Loop quadrant system (walk at any angle, jump orthogonally)

## [3.1] - 2020-08-11
### Added
- Angel Island tiles
- Serialization module (represent data as string)

### Changed
- Original feature: Reduced Deceleration on Descending Slope
- Original feature: No Friction on Steep Descending Slope
- Original feature: Progressive Ascending Slope Factor
- Set minimum playback speed for Running animation
- Reduced tokens heavily by extracting code in modules and using data serialization

## [3.0] - 2020-07-11
### Added
- Game: split airborne state into falling and air_spin to only play Spin animation on jump
- Game: when going airborne/grounded, adapt height and center position so Sonic hits the ceiling when we expect by looking at the sprite
- Test: convert itests to new DSL system

### Changed
- Project: extracted engine as submodule pico-boots, adapted build pipeline
- Game: set pink as transparent color for Sonic sprites to match new…
- Game: preserve last animation (including playback speed) when falling
- Game: only allow ceiling detection during descending motion if abs(vel.x) > abs(vel.y)
- Test: improved itests

## [2.3-sprite-anim] - 2019-05-16
### Added
- Engine: sprite animation system
- Game: press X to toggle debug motion
- Game: added air motion block with wall, ceiling and landing
- Game: character running animation
- Game: character can run on slopes
- Test: added itest for running up a slope
- Test: convert itests to new DSL system

### Changed
- Project: split engine and game folders properly
- Engine: misc logging fixes
- Game: clamp ground speed on acceleration
- Game: fixed sticky jump input during jump
- Game: fixed air motion pixel flooring system

## [2.2] - 2018-10-31
### Added
- Game: added Air Spin sprite used when airborne
- Test: completed 100% coverage on player character

### Changed
- Game: fixed ground speed accumulating during wall block
- Game: character is blocked by ceiling and diagonal tiles
- Game: cleaner wall block by cutting subpixels

## [2.1] - 2018-10-27
### Added
- Game: character snaps to lower ground when walking
- Game: character falls when walking off a cliff
- Game: character can jump with air control (X axis motion)
- Game: apply artificial gravity after jump interrupt, allow hop on 1-frame jumps

## [2.0-flat-ground] - 2018-09-09
### Added
- Game: character can walk on flat ground
- Test: added support for #solo for headless itests

## [2.0-land] - 2018-09-08
### Added
- Game: blue sky background
- Game: added gravity, character can fall and land on ground
- Test: integration (simulation) test system aka "itests"

### Changed
- Engine: improved logging, classes, math

## [1.0] - 2018-07-06
### Added
- Engine: application: constants, flow with gamestates
- Engine: core modules: class, coroutine, helper, math
- Engine: debug tools: codetuner, logging, profiler using WTK
- Engine: input: mouse input and button IDs
- Engine: render: color constants and sprite render
- Engine: UI: render mouse and overlay system
- Engine: build: basic build pipeline with data.p8 and post-build replace strings script
- Game: gamestates title menu, in-game, credits (empty)
- Game: menu: simple titlemenu to start the debug stage
- Game: in-game: stage shows title on start, plays BGM, has goal
- Game: in-game: debug character flies X/Y on directional input, go back to title menu on reach goal
- Test: all busted unit tests in separator folder tests

[Unreleased]: https://github.com/hsandt/sonic-pico8/compare/v5.0...HEAD
[5.0]: https://github.com/hsandt/sonic-pico8/compare/v4.2...v4.3
[4.2]: https://github.com/hsandt/sonic-pico8/compare/v4.1...v4.2
[4.1]: https://github.com/hsandt/sonic-pico8/compare/v4.0...v4.1
[4.0]: https://github.com/hsandt/sonic-pico8/compare/v3.1...v4.0
[3.1]: https://github.com/hsandt/sonic-pico8/compare/v3.0...v3.1
[3.0]: https://github.com/hsandt/sonic-pico8/compare/v2.3-sprite-anim...v3.0
[2.3-sprite-anim]: https://github.com/hsandt/sonic-pico8/compare/v2.2...v2.3-sprite-anim
[2.2]: https://github.com/hsandt/sonic-pico8/compare/v2.1...v2.2
[2.1]: https://github.com/hsandt/sonic-pico8/compare/v2.0-flat-ground...v2.1
[2.0-flat-ground]: https://github.com/hsandt/sonic-pico8/compare/v2.0-land...v2.0-flat-ground
[2.0-land]: https://github.com/hsandt/sonic-pico8/compare/v1.0-framework...v2.0-land
[1.0-framework]: https://github.com/hsandt/sonic-pico8/releases/tag/v1.0-framework
