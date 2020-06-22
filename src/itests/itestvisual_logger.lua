-- gamestates: titlemenu
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local logging = require("engine/debug/logging")
local vlogger = require("engine/debug/visual_logger")
local flow = require("engine/application/flow")

-- TODO: update to new format with helper functions (see itesttitlemenu.lua)
local itest = integration_test('human test: visual logger is displayed correctly', {':titlemenu'})

itest.setup = function (app)
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(vlogger.vlog_stream)

  -- in case default changes, set it here for precise testing
  vlogger.buffer_size = 5
  vlogger.window:init()

  vlogger.window:show()
  flow:change_gamestate_by_type(':titlemenu')
end

local old_console_log_stream_active

itest:add_action(time_trigger(30, true), function ()
  old_console_log_stream_active = logging.console_log_stream.active
  logging.console_log_stream.active = false  -- hide those messages from the console log, we want to test the visual log
  log("info message", "itest")
end)
itest:add_action(time_trigger(30, true), function ()
  log("info message 2", "itest")
end)
itest:add_action(time_trigger(30, true), function ()
  warn("warning message\none 2 lines", "itest")
end)
itest:add_action(time_trigger(30, true), function ()
  err("error message 1", "itest")
end)
itest:add_action(time_trigger(30, true), function ()
  err(wwrap("very long error message", 5), "itest")
end)
itest:add_action(time_trigger(50, true), function ()
  log("pushing up 1", "itest")
end)
itest:add_action(time_trigger(50, true), function ()
  log("pushing up 2", "itest")
end)
itest:add_action(time_trigger(50, true), function ()
  log("pushing up 3", "itest")
  logging.console_log_stream.active = old_console_log_stream_active
  vlogger.vlog_stream.active = false  -- hide visual log again, so we don't print the success message in the vertical layout
end)

-- human check: before "pushing up" messages, add new messages. then pop top messages each time.
itest.final_assertion = function ()
  return true, ""
end

itest_manager:register(itest)
