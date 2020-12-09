-- engine bustedhelper equivalent for game project
-- it adds ingame common module, since the original bustedhelper.lua
--  is part of engine and therefore cannot reference game modules
-- it also adds visual ingame add-on to simulate main providing it to any ingame scripts
--  this is useful even when the utest doesn't test visual data usage directly,
--  as some modules like stage_state and tile_test_data define outer scope vars
--  relying on ingame visual data
-- Usage:
--  in your game utests, always require("test/bustedhelper_stage_clear") at the top
--  instead of "engine/test/bustedhelper"
require("engine/test/bustedhelper")
require("common_stage_clear")
-- we still need to draw goal plate and emeralds, so keep using ingame visuals during stage_clear
require("resources/visual_ingame_addon")
