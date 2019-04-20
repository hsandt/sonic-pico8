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
logging.logger:register_stream(logging.file_log_stream)
--#endif

local codetuner = require("engine/debug/codetuner")

local current_itest_index = 0

function _init()
--#if log
  -- clear log file on new itest session
  logging.file_log_stream:clear()
--#endif

  -- require only gamestate modules written on first line of the required $itest (pico8-build way)
  gamestate_proxy:require_gamestates()

  -- start first itest
  init_game_and_start_next_itest()
end

function _update60()
  handle_input()
  itest_runner:update_game_and_test()
end

function _draw()
  itest_runner:draw_game_and_test()
end

function init_game_and_start_next_itest()
  init_game_and_start_itest_by_relative_index(1)
end

function init_game_and_start_itest_by_relative_index(delta)
  -- clamp new index
  local new_index = mid(1, current_itest_index + delta, #itest_manager.itests)
  -- check that an effective idnex change occurs
  if new_index ~= current_itest_index then
    current_itest_index = new_index
    itest_manager:init_game_and_start_by_index(new_index)
  end
end

-- press left/right to navigate freely in itests, even if not finished
-- press x to skip itest only if finished
function handle_input()
  -- since input.mode is simulated during itests, use pico8 api directly for input
  if btnp(button_ids.left) then
    -- go back to previous itest
    init_game_and_start_itest_by_relative_index(-1)
    return
  elseif btnp(button_ids.right) then
    -- skip current itest
    init_game_and_start_next_itest()
    return
  elseif btnp(button_ids.up) then
    -- go back 10 itests
    init_game_and_start_itest_by_relative_index(-10)
    return
  elseif btnp(button_ids.down) then
    -- skip many itests
    init_game_and_start_itest_by_relative_index(10)
    return
  end

  if itest_runner.current_state == test_states.success or
    itest_runner.current_state == test_states.failure or
    itest_runner.current_state == test_states.timeout then
    -- previous itest has finished, wait for x press to continue to next itest
    if btnp(button_ids.x) then
      init_game_and_start_next_itest()
    end
  end
end
