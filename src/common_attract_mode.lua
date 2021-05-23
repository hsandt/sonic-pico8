-- Require all common attract_mode modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for attract_mode cartridge.
-- Usage: add require("common_attract_mode") at the top of each of your attract_mode main scripts
--  (along with "engine/common") and in bustedhelper_attract_mode

require("engine/core/angle")
require("engine/core/vector_ext_angle")
require("engine/core/table_helper")


--#if minify_level3

-- in this particular project, this happens to be defined early anyway,
--  but to be safe
require("engine/render/animated_sprite_data_enums")

--#endif

require("data/sprite_flags")
require("ingame/playercharacter_enums")

--[[#pico8
--#if unity

-- see explanations in common_ingame.lua
require("ordered_require_attract_mode")

--#endif
--#pico8]]
