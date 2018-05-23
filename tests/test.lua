-- required module for all tests
require("pico8api")

-- mute all messages during tests
require("engine/debug/debug")
current_debug_level = debug_level.none
