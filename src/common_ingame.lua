-- Require all common ingame modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for ingame cartridge.
-- Usage: add require("common_ingame") at the top of each of your ingame main scripts
--  (along with "engine/common") and in bustedhelper_ingame

require("engine/core/angle")  -- used by playercharacter, so technically not needed for stage_clear
require("engine/core/vector_ext_angle")
require("engine/core/table_helper")


--#if minify_level3

--#if itest
-- itest_dsl uses them
require("engine/core/enum")
require("engine/core/string_split")
require("engine/test/assertions")
--#endif

-- in this particular project, this happens to be defined early anyway,
--  but to be safe
require("engine/render/animated_sprite_data_enums")

--#endif

require("data/sprite_flags")
require("ingame/playercharacter_enums")

--#if recorder
-- exceptionally a global non-constant variable to easily access and print for action recording
-- (we don't build stage ingame with #recorder, only attract_mode, but we could; and headless itests
--  do run the game as if all symbols were active)
total_frames = 0
--#endif

--[[#pico8
--#if unity
-- When doing a unity build, all modules must be concatenated in dependency, with modules relied upon
--  above modules relying on them.
-- This matters for two reasons:
--  1. Some statements are done in outer scope and rely on other modules (derived_class(), data tables defining
--   sprite_data(), table merge(), etc.) so the struct/class/function used must be defined at evaluation time,
--   and there is no picotool package definition callback wrapper to delay package evaluation to main evaluation
--   time (which is done at the end).
--  2. Even in inner scope (method calls), statements refer to named modules normally stored in local vars via
--     require. In theory, *declaring* the local module at the top of whole file and defining it at runtime
--     at any point before main is evaluation would be enough, but it's cumbersome to remove "local" in front
--     of the local my_module = ... inside each package definition, so we prefer reordering the packages
--     so that the declaration-definition is always above all usages.
-- Interestingly, ordered_require will contain the global requires in this very file (keeping same order)
--  for minification lvl3, but it redundancy doesn't matter as all require calls will be stripped.

require("ordered_require_ingame")

--#endif
--#pico8]]
