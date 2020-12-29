-- Require all common stage_intro modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for stage_intro cartridge.
-- Usage: add require("common_stage_intro") at the top of each of your stage_intro main scripts
--  (along with "engine/common") and in bustedhelper_stage_intro

require("engine/core/table_helper")  -- merge (to add the visual_stage_intro_addon and visual_menu_addon)

-- we need sprite flags to draw grass on top of the rest
require("data/sprite_flags")

-- just kept for the scripted player character fall (there is no real physics so we could also get
--  around using actual motion states)
require("ingame/playercharacter_enums")

--[[#pico8
--#if unity

-- see explanations in common_ingame.lua
require("ordered_require_stage_intro")

--#endif
--#pico8]]
