# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/hsandt/sonic-pico8/compare/v3.0...HEAD
[3.1]: https://github.com/hsandt/sonic-pico8/compare/v3.0-sprite-anim...v3.1
[3.0]: https://github.com/hsandt/sonic-pico8/compare/v2.3-sprite-anim...v3.0
[2.3-sprite-anim]: https://github.com/hsandt/sonic-pico8/compare/v2.2...v2.3-sprite-anim
[2.2]: https://github.com/hsandt/sonic-pico8/compare/v2.1...v2.2
[2.1]: https://github.com/hsandt/sonic-pico8/compare/v2.0-flat-ground...v2.1
[2.0-flat-ground]: https://github.com/hsandt/sonic-pico8/compare/v2.0-land...v2.0-flat-ground
[2.0-land]: https://github.com/hsandt/sonic-pico8/compare/v1.0-framework...v2.0-land
[1.0-framework]: https://github.com/hsandt/sonic-pico8/releases/tag/v1.0-framework
