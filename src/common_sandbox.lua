-- Require all common sandbox modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for sandbox cartridge.
-- Usage: add require("common_sandbox") at the top of each of your sandbox main scripts
--  (along with "engine/common") and in bustedhelper_sandbox

require("engine/core/angle")  -- used by playercharacter, so technically not needed for stage_clear
require("engine/core/vector_ext_angle")
require("engine/core/table_helper")

--#if minify_level3
require("engine/render/animated_sprite_data_enums")
--#endif

require("data/sprite_flags")
require("ingame/playercharacter_enums")

--[[#pico8
--#if unity

-- see explanations in common_ingame.lua
require("ordered_require_sandbox")

--#endif
--#pico8]]
