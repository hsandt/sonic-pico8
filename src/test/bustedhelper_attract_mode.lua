-- engine bustedhelper equivalent for game project
-- see bustedhelper_ingame.lua for explanations
-- attract_mode being the closest to ingame cartridge, we have the same content
-- except we require common_attract_mode and removed uncommented log activation code
-- Usage:
--  in your game utests, always require("test/bustedhelper_attract_mode") at the top
--  instead of "engine/test/bustedhelper"
require("engine/test/bustedhelper")
require("common_attract_mode")
require("resources/visual_ingame_addon")
