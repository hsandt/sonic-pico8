-- Require all common ingame modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for ingame cartridge.
-- Usage: add require("common_ingame") at the top of each of your ingame main scripts
--  (along with "engine/common") and in bustedhelper_ingame

require("engine/core/direction_ext")
require("engine/core/vector_ext")
require("engine/core/table_helper")

--#if minify_level3
-- early declaration of spr_r for minification by -G
-- see comment on strspl in common_titlemenu, except it replaces
-- require("engine/render/sprite")
spr_r = 0
--#endif

require("data/sprite_flags")
require("ingame/playercharacter_enums")
