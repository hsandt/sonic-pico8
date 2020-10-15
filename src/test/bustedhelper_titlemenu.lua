-- engine bustedhelper equivalent for game project
-- it adds game common module, since the original bustedhelper.lua
--  is part of engine and therefore cannot reference game modules
-- it also adds visual titlemenu add-on to simulate main providing it to any titlemenu scripts
-- Usage:
--  in your titlemenu module utests, always require("test/bustedhelper_titlemenu")
--  at the top instead of "engine/test/bustedhelper"
require("engine/test/bustedhelper")
require("resources/visual_titlemenu_addon")
