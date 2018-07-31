-- gamestates: titlemenu
require("engine/test/integrationtest")
local logging = require("engine/debug/logging")
local visual_logger = require("engine/debug/visual_logger")
local flow = require("engine/application/flow")
local gamestate = require("game/application/gamestate")

local itest = integration_test('human test: visual logger is displayed correctly', {gamestate.types.titlemenu})

itest.setup = function ()
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(visual_logger.visual_log_stream)

  -- in case default changes, set it here for precise testing
  visual_logger.buffer_size = 5
  visual_logger.window:init()

  visual_logger.window:show()
  flow:change_gamestate_by_type(gamestate.types.titlemenu)
end

itest:add_action(time_trigger(0.5), function ()
  logging.console_log_stream.active = false  -- hide those messages from the console log, we want to test the visual log
  log("info message", "itest")
end)
itest:add_action(time_trigger(0.5), function ()
  log("info message 2", "itest")
end)
itest:add_action(time_trigger(0.5), function ()
  warn("warning message", "itest")
end)
itest:add_action(time_trigger(0.5), function ()
  err("error message 1", "itest")
end)
itest:add_action(time_trigger(0.5), function ()
  err("error message 2", "itest")
end)
itest:add_action(time_trigger(0.7), function ()
  log("pushing up 1", "itest")
end)
itest:add_action(time_trigger(0.7), function ()
  log("pushing up 2", "itest")
end)
itest:add_action(time_trigger(0.7), function ()
  log("pushing up 3", "itest")
  logging.console_log_stream.active = true
  visual_logger.visual_log_stream.active = false  -- hide visual log again, so we don't print the success message in the vertical layout
end)

-- human check: before "pushing up" messages, add new messages. then pop top messages each time.
itest.final_assertion = function ()
  return true, ""
end

itest_manager:register(itest)
