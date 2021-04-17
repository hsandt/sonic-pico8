-- engine bustedhelper equivalent for game project
-- it adds ingame common module, since the original bustedhelper.lua
--  is part of engine and therefore cannot reference game modules
-- it also adds visual ingame add-on to simulate main providing it to any ingame scripts
--  this is useful even when the utest doesn't test visual data usage directly,
--  as some modules like stage_state and tile_test_data define outer scope vars
--  relying on ingame visual data
-- Usage:
--  in your game utests, always require("test/bustedhelper_ingame") at the top
--  instead of "engine/test/bustedhelper"
require("engine/test/bustedhelper")
require("common_ingame")
require("resources/visual_ingame_addon")

-- uncomment below just when you need to see log during utests
--[[
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
logging.logger.active_categories = {
  -- engine
  ['default'] = true,
  -- ['codetuner'] = true,
  -- ['flow'] = true,
  -- ['itest'] = true,
  -- ['log'] = true,
  -- ['ui'] = true,
  -- ['reload'] = true,
  ['trace'] = true,
  ['trace2'] = true,
  -- ['frame'] = true,

  -- game
  -- ['loop'] = true,
  -- ['emerald'] = true,
  -- ['palm'] = true,
  -- ['ramp'] = true,
  -- ['goal'] = true,
  -- ['spring'] = true,
}
--]]
