-- engine bustedhelper equivalent for game project
-- it adds stage_intro common module, since the original bustedhelper.lua
--  is part of engine and therefore cannot reference game modules
-- it also adds visual stage_intro add-on to simulate main providing it to any stage_intro scripts
--  this is useful even when the utest doesn't test visual data usage directly,
--  as some modules like stage_state and tile_test_data define outer scope vars
--  relying on stage_intro visual data
-- Usage:
--  in your game utests, always require("test/bustedhelper_stage_intro") at the top
--  instead of "engine/test/bustedhelper"
require("engine/test/bustedhelper")
require("common_stage_intro")
require("resources/visual_stage_intro_addon")
