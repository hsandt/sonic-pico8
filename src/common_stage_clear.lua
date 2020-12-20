-- Require all common stage_clear modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for stage_clear cartridge.
-- Usage: add require("common_stage_clear") at the top of each of your stage_clear main scripts
--  (along with "engine/common") and in bustedhelper_stage_clear

require("engine/core/fun_helper")    -- unpacking
require("engine/core/table_helper")  -- merge (to add the visual_ingame_addon and visual_menu_addon)

-- we need sprite flags to draw grass on top of the rest
require("data/sprite_flags")
