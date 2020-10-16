-- Require all common game modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for game.
-- Usage: add require("common") at the top of each of your main scripts
--  (along with "engine/common") and in bustedhelper (after pico8api)

require("engine/core/direction_ext")
require("engine/core/vector_ext")
require("engine/core/seq_helper")
require("data/sprite_flags")
