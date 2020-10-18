-- Require all common ingame modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for ingame cartridge.
-- Usage: add require("common_ingame") at the top of each of your ingame main scripts
--  (along with "engine/common") and in bustedhelper (after pico8api)

require("engine/core/direction_ext")
require("engine/core/vector_ext")
require("engine/core/seq_helper")
require("engine/core/table_helper")

require("data/sprite_flags")
require("ingame/playercharacter_enums")
