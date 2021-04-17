-- Require all common titlemenu modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for titlemenu cartridge.
-- Usage: add require("common_titlemenu") at the top of each of your titlemenu main scripts
--  (along with "engine/common") and in bustedhelper_titlemenu

require("engine/core/fun_helper")    -- unpacking
require("engine/core/table_helper")

--#if minify_level3

-- string_split defines strspl which is used in particular by text_helper
-- but text_helper is required at a deeper level so we require it here
-- to have early definition
-- we used to just define strspl = 0 for compactness, but we now use unity build
-- when possible, which strips any redundant requires (after minification)
require("engine/core/string_split")

--#endif

--[[#pico8
--#if unity

-- see explanations in common_ingame.lua
require("ordered_require_titlemenu")

--#endif
--#pico8]]
