# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [7.0] - 2023-02-05
### Added
- Ending credits: add "thank you for playing!" text at the end with custom font, adding character "!" + spacing info to custom font

### Changed
- Ending credits: fix ending text using custom font being offset
- Ending credits: loop BGM, arranging track a little around the loop so it flows better, and fade out music at the end

## [6.3] - 2023-02-05
### Added
- Splash screen: add splash screen on cart boot, before title menu. It is based on Sonic 2's splash screen, except it shows "SAGE". The choir voice is played using the new PCM system of PICO-8.
- Transition: the splash screen fades out and back in into the title menu. Player can also manually skip it by pressing O or X
- Stage clear: when player missed some emeralds, show Eggman juggling with the missed ones as in Sonic 1 TRY AGAIN screen. Press left/right to switch between 2 juggling modes.
- Stage clear: when played finished the game with all the emeralds, play ending credits (staff roll) similar to Sonic 3. Use a custom font adapted from "Andes" for PICO-8, using the new custom font feature. The music is adapted from Sonic 3 (not Sonic 3 & Knuckles). Known issue: names are offset and music doesn't loop.

### Changed
- Title menu: upgrade title logo to show Sonic with a moving hand as in Sonic 1. Also update cart label to reflect the new title logo.
- Title menu: play sparks with SFX because the title logo shows as in Sonic 2. Press O or X to directly jump into the menu (sparks still show).
- Title menu: fix angel island background top pixels staying during start cinematic
- Title menu: Credits: revamped menu credits with new background (similar to Sonic 2 options) and more spaced text. In counterpart, player can scroll through the whole page. Also added input hints.
- Stage clear: press O or X to skip stage result
- Stage clear: fix 2 red pixels on screen during stage result

## [6.2] - 2022-06-13
### Added
- Stage intro: it now shows a full sequence before entering ingame. It follows the Start cinematic played in the title menu, and shows Sonic landing on pico island. It ends with the usual splash screen.
- Character visual: play landing animation when landing at a speed Y of 3.9 or more (only enabled for Stage intro)

### Changed
- Character physics: fixed character able to fall below the ground due to discrete collision tunneling when landing at high speed on the ground (this could happen when jumping from the highest to the lowest platforms in the stage). The terminal velocity on Y is now set to 7 to prevent this (with some safety margin).
- Stage data/visual: moved waterfall and start position 2 tiles to the right. Adjusted Attract Mode sequence to take this into account.
- Stage visual: Fixed palm tree left/right top sprite part never being shown by fixing sprite coordinates in visual data for ingame

## [6.1] - 2021-08-30
### Added
- Start cinematic: when pressing Start in title menu, before loading stage intro, play a full cinematic showing emeralds scattering on the island and Sonic jumping there to hunt them. Can be skipped by pressing either O or X. Ends with fade out either way.
- Stage visual: added tiles for leaves oriented left and right for transition between first wooden wall and forest background (background leaves), and in various places for a horizontal transition between full leaves tiles and void (foreground leaves)

### Changed
- Title menu: player can also press X (instead of just O) to immediately show menu
- Credits: added "komehara" as developer alias, rearranged lines to fit

## [6.0] - 2021-08-17
### Added
- Character physics: spin dash (includes crouching)
- Character physics: allow late jump up to 6 frames after leaving ground, to mimic modern platformer physics (can be disabled in pause menu)
- Animation: crouch and spin dash animations, using new dynamic sprite reloading system to allow even more sprites on a single spritesheet (unfortunately smoke PFX was cut from Release as it took too many characters, although still present in code)
- Camera: spin dash lag
- Stage visual: added animated waterfalls at the beginning of the level (they actually use color palette swapping as in the original game)
- Attract mode: added Attract mode when player waits for end of intro BGM on the title screen. This is played inside a new cartridge that is mostly a stripped version of the ingame cartridge + a puppet sequence to make Sonic move by himself

### Changed
- Application: upgraded to PICO-8 0.2.2c with full binary patching and upgraded custom web template to integrate latest improvements
- UI: press O on title menu before menu appears to make it appear immediately
- Credits: add mention of SAGE and itch.io URL
- Stage physics: fixed last descending slope tile connecting slope and loop having no collision
- Stage physics/visual: reworked rock sprites to be smaller
- Stage physics/visual: offset last emerald (orange) by 5px to the right
- Stage physics/visual: replaced very low slopes with 1px bumps that are still considered flat ground to avoid slowing down character when running on them, while keeping the funny up-and-down motion
- Camera: use small vertical window even on ground to avoid moving when character just moves by 1px up and down (due to new bumps)
- Stage visual: hide emerald behind leaves to make harder to find
- Stage visual: improved forest hole lightshaft in background (now sprite instead of procedurally generated)
- Stage visual: fixed one-way platform grass appearing in front of character
- Stage visual: fixed background parallax to only move when camera moves by an integer pixel, not pixel fractions
- Character physics: fixed detecting flat ground when running down slopes where some columns of the collision mask are empty
- Character physics & Optimization: big overhaul with switch to "big steps" method instead of the expensive "pixel step" method. This applies to both grounded and airborne motion. First move by the full motion you'd expect on a single frame, ignoring obstacles. Then detect wall, ground and ceiling (depending on motion direction), and escape from those colliders if inside, as in the original games (we also have an extra final wall check if grounded and changed quadrant to avoid getting stuck). This effectively reduced complexity from O(speed) to O(1) and allows the game to run at 60 FPS consistently (with only a few 30 FPS drops when reloading memory e.g. to change region). This also fixed the various bugs where character would get stuck in curves and loops when moving at high speed.
- Optimization: optimized the sprite rotation method to use efficient code specific for 90-degree rotations, instead of general trigonometry with backward approach (particularly slow due to iterating on all pixels inside the bounding box containing a given disc).
- Compressed characters: various refactoring and replacement of every constant with hardcoded strings/values (as pre-build step) to reduce compressed characters size and allow exporting cartridge again despite adding new features
- Debug: fix and improve debug rays (development only)
- Export: merged audio data with built-in ingame data cartridge to avoid going over the limit of 16 cartridges per export (attract mode cartridge). Also offset BGM tracks by 8 tracks to allow custom instruments to be used ingame. This was required for the new spin dash SFX.

## [5.4] - 2021-04-17
### Added
- Audio: added "got all emeralds" jingle with delay
- Audio: added menu swipe (zigzag fade-out) SFX during stage clear
- Character physics: character can land on ceiling corners up to 45 degrees
- Character physics: fixed character jittering when walking down from the top of the first curved slope to the left. Now, character falls when ground angle changes by 45 degrees or more. This is an original feature and differs from Sonic 3, which would let Sonic stick to the curved slope while running as if it was flat ground.

### Changed
- Stage intro: fixed fade-in color palette swap not applied on first frame
- Stage clear: do not show "Retry (keep emeralds)" if you got 0 emeralds
- Export (web): improved HTML template to just fit the game canvas
- Export: stripped some unused code/data for smaller cartridge
- Engine: updated pico-boots and adapted API calls

## [5.3] - 2021-02-01
### Added
- Stage: added horizontal springs (internally now fully-fledged objects instead of tiles)

### Changed
- Physics: removed original slope features, namely Progressive Ascending Steep Slope Factor, Reduced Deceleration on Steep Descending Slope and No Friction on Steep Descending Slope (stripped unless symbol #original_slope_features is defined, which no build config currently uses). No strong impact on gameplay observed across Pico Island stage
- Stage clear: fixed "Angel Island" -> "Pico Island"

## [5.2] - 2021-01-12
### Added
- Titlemenu: added version number in top-right corner
- Stage intro: stage fades in with gradual color darkness (palette swap)
- System: Added menu entries to retry with and without emeralds
- Physics: added one-way platform system. Added one-way platform tiles and integrated them in stage
- Stage clear: added retry screen with missed emeralds and options to retry with or without emerald, or go back to title menu
- Stage clear: retry screen fades in and out with a zigzag swipe animation and/or gradual color darkness (palette swap)
- Export: improved export script to patch standalone and web automatically (supports > 8192 tokens, no lag on reload())
- Export: always load cartridge via basename (without extension) and modify loading path in PNG cartridges (".p8.png") to fix load/reload
- Export: generate .zip archives after export
- Upload: added upload script to immediately upload to itch.io via butler

### Changed
- Titlemenu: fixed top of 'O' in "SONIC" in title logo
- Stage intro: extracted stage intro into its own cartridge (so ingame cartridge has fewer characters ad can be exported). This introduced a small loading lag after stage intro, and player character cannot move during intro
- Sprite: fixed top row of some Sonic rotated run sprites missing
- Sprite: reduced emerald size by 2px in both directions, adjusted HUD
- Stage clear: removed emerald cross, arranged emerald position to match retry screen
- Export: fixed export scripts to take all stage regions into account
- Export: fixed app icon, changed label to show title screen (without menu)

## [5.1] - 2020-12-17
### Changed
- Audio: fixed Travis release for GitHub forgetting to upload BGM cartridge (a glitchy version of Green Hill Zone was played instead of Angel Island)

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

[Unreleased]: https://github.com/hsandt/sonic-pico8/compare/v7.0...HEAD
[6.3]: https://github.com/hsandt/sonic-pico8/compare/v6.3...v7.0
[6.3]: https://github.com/hsandt/sonic-pico8/compare/v6.2...v6.3
[6.2]: https://github.com/hsandt/sonic-pico8/compare/v6.1...v6.2
[6.1]: https://github.com/hsandt/sonic-pico8/compare/v6.0...v6.1
[6.0]: https://github.com/hsandt/sonic-pico8/compare/v5.3...v6.0
[5.3]: https://github.com/hsandt/sonic-pico8/compare/v5.2...v5.3
[5.2]: https://github.com/hsandt/sonic-pico8/compare/v5.1...v5.2
[5.1]: https://github.com/hsandt/sonic-pico8/compare/v5.0...v5.1
[5.0]: https://github.com/hsandt/sonic-pico8/compare/v4.2...v5.0
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
