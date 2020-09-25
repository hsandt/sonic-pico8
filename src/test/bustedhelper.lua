-- engine bustedhelper equivalent for game project
-- it simply adds game common module, since the original bustedhelper.lua
--  is part of engine and therefore cannot reference game modules
-- Usage:
--  in your game utests, always require("test/bustedhelper") at the top
--  instead of "engine/test/bustedhelper"
require("engine/test/bustedhelper")
require("common_ingame")
