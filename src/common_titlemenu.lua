-- Require all common titlemenu modules (used across various scripts in game project)
--  that define globals and don't return a module table
-- Equivalent to engine/common.lua but for titlemenu cartridge.
-- Usage: add require("common_titlemenu") at the top of each of your titlemenu main scripts
--  (along with "engine/common") and in bustedhelper (after pico8api)

require("engine/core/fun_helper")
require("engine/core/table_helper")
