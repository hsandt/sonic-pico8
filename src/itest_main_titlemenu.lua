-- main source file for all itests, used to run itests in pico8

-- must require at main top, to be used in any required modules from here
require("engine/pico8/api")
require("engine/common")

local integrationtest = require("engine/test/integrationtest")
local itest_manager = integrationtest.itest_manager

local picosonic_app_titlemenu = require("application/picosonic_app_titlemenu")

-- set app immediately so during itest registration by require,
--   time_trigger can access app fps
local app = picosonic_app_titlemenu()
itest_runner.app = app

-- tag to add require for itest files here
--[[add_require]]

function _init()
--#if log
  -- register log streams to output logs to both the console and the file log
  logging.logger:register_stream(logging.console_log_stream)
  logging.logger:register_stream(logging.file_log_stream)
  logging.file_log_stream.file_prefix = "picosonic_itest_titlemenu"

  -- clear log file on new itest session
  logging.file_log_stream:clear()

  logging.logger.active_categories = {
    -- engine
    ['default'] = true,
    -- ['codetuner'] = nil,
    -- ['flow'] = nil,
    ['itest'] = true,
    -- ['log'] = nil,
    -- ['ui'] = nil,
    ['frame'] = true,
    ['trace'] = true,
    ['spring'] = true,

    -- game
    -- ['...'] = true,
  }
--#endif

  picosonic_app_titlemenu.initial_gamestate = ':titlemenu'

  -- start first itest
  if #itest_manager.itests > 0 then
    itest_manager:init_game_and_start_next_itest()
  end
end

function _update60()
  itest_manager:handle_input()
  itest_runner:update_game_and_test()
end

function _draw()
  itest_runner:draw_game_and_test()
end
