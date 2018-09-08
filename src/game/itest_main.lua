-- main source file for all itests, used to run itests in pico8
-- each itest should be put inside the tests/itests folder with the name itest{module}.lua
-- and its first line should be "-- gamestates: state1, state2, ..." with the list of states
-- to use for the build. other states will be replaced with dummy equivalents.

require("engine/test/integrationtest")
require("game/itests/itest$itest")
local gamestate_proxy = require("game/application/gamestate_proxy")
local input = require("engine/input/input")

--#if log
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
--#endif

local current_itest_index = 0

function _init()
  -- require only gamestate modules written on first line of the required $itest (pico8-build way)
  gamestate_proxy:require_gamestates()

  -- start first itest
  init_game_and_start_next_itest()
end

function _update60()
  handle_input()
  integration_test_runner:update_game_and_test()
end

function _draw()
  integration_test_runner:draw_game_and_test()
end

function init_game_and_start_next_itest()
  if #itest_manager.itests > current_itest_index then
    current_itest_index += 1
    itest_manager:init_game_and_start_by_index(current_itest_index)
  end
end

function handle_input()
  if integration_test_runner.current_state == test_states.success or
    integration_test_runner.current_state == test_states.failure or
    integration_test_runner.current_state == test_states.timeout then
    -- previous itest has finished, wait for x press to continue
    --  to next itest
    -- since input.mode is simulated during itests, use pico8 api directly
    if btnp(button_ids.x) then
      init_game_and_start_next_itest()
    end
  end
end
