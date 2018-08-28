-- main source file for all itests, used to run itests in pico8
-- each itest should be put inside the tests/itests folder with the name itest{module}.lua
-- and its first line should be "-- gamestates: state1, state2, ..." with the list of states
-- to use for the build. other states will be replaced with dummy equivalents.

require("engine/test/integrationtest")
require("game/itests/itest$itest")
local gamestate_proxy = require("game/application/gamestate_proxy")

--#if log
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
--#endif

function _init()
  -- require only gamestate modules written on first line of the required $itest (pico8-build way)
  gamestate_proxy:require_gamestates()

  -- temporary way to run single itest
  -- when itest files start having multiple tests, you'll need a name-based search test running
  for itest_name, itest in pairs(itest_manager.itests) do
    itest_manager:init_game_and_start_by_name(itest_name)
    break
  end
end

function _update60()
  integration_test_runner:update_game_and_test()
end

function _draw()
  integration_test_runner:draw_game_and_test()
end
