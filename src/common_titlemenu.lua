-- Require all common titlemenu modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for titlemenu cartridge.
-- Usage: add require("common_titlemenu") at the top of each of your titlemenu main scripts
--  (along with "engine/common") and in bustedhelper_titlemenu

require("engine/core/fun_helper")    -- unpacking
require("engine/core/table_helper")

--#if minify_level3
-- early declaration of strspl for minification by -G
-- in our case, assigning anything is safe because common_titlemenu is required
--  at runtime before any other modules that may indirectly need string_split
--  (we are talking runtime execution here, not parsing order) so it won't
--  overwrite the true definition of strspl, and we don't need to surround with
--  `if nil` as with `require = 0` in engine/common.
-- we can also require("engine/core/string_split") if we need more functions from
--  that module, or for some reason the require order would make it unsafe
-- (we would then have some redundancy as text_helper requires string_split on its own
--   since it is not part of engine/common)
strspl = 0
--#endif

--[[#pico8
--#if unity

-- see explanations in common_ingame.lua
require("ordered_require_titlemenu")

--#endif
--#pico8]]
