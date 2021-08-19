-- See common_ingame.lua for explanations, since attract_mode is very close to ingame

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

--#if recorder
-- exceptionally a global non-constant variable to easily access and print for action recording
total_frames = 0
--#endif

--[[#pico8
--#if unity

-- see explanations in common_ingame.lua
require("ordered_require_attract_mode")

--#endif
--#pico8]]
