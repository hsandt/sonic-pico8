require("engine/application/constants")
require("engine/core/class")
require("engine/render/color")
require("engine/test/assertions")
local debug = require("engine/debug/debug")
local gameapp = require("game/application/gameapp")
local input = require("engine/input/input")

test_states = {
  none = 'none',          -- no test started
  running = 'running',    -- the test is still running
  success = 'success',    -- the test has just succeeded
  failure = 'failure',    -- the test has just failed
  timeout = 'timeout'     -- the test has timed out
}

-- integration test runner singleton
integration_test_runner = singleton {
  initialized = false,
  current_test = nil,
  current_frame = 0,
  _last_trigger_frame = 0,
  _next_action_index = 1,
  current_state = test_states.none,
  current_message = nil              -- only defined when current_state is failure
}

-- helper method to use in rendered itest _init
function integration_test_runner:init_game_and_start(test)
  gameapp.init()
  integration_test_runner:start(test)
end

-- helper method to use in rendered itest _update60
function integration_test_runner:update_game_and_test()
  if self.current_state == test_states.running then
    gameapp.update()
    self:update()
    if self.current_state ~= test_states.running then
      log("itest '"..self.current_test.name.."' ended with "..self.current_state, "itest")
    end
  end
end

-- helper method to use in rendered itest _draw
function integration_test_runner:draw_game_and_test()
  gameapp.draw()
  self:draw()
end

function integration_test_runner:start(test)
  if not self.initialized then
    self:_init()
  end

  if self.current_test then
    self:stop()
  end

  self.current_test = test
  self.current_state = test_states.running

  if test.setup then
    test:setup()
  end

  -- edge case: 0 actions in the action sequence. check end
  -- immediately to avoid out of bounds index in _check_next_action
  if not self:_check_end() then
    self:_check_next_action()
  end
end

function integration_test_runner:update()
  assert(self.current_test, "integration_test_runner:update: current_test is not set")
  if self.current_state ~= test_states.running then
    -- the current test is over and we already got the result
    -- do nothing and fail silently (to avoid crashing
    -- just because we repeated update a bit too much in utests)
    return
  end

  -- advance time
  self.current_frame = self.current_frame + 1

  -- check for timeout (if not 0)
  if self.current_test:check_timeout(self.current_frame) then
    self.current_state = test_states.timeout
  else
    self:_check_next_action()
  end
end

function integration_test_runner:draw()
  assert(self.current_test, "integration_test_runner:draw: current_test is not set")
  api.print(self.current_test.name, 2, 2, colors.yellow)
  api.print(self.current_state, 2, 9, self:_get_test_state_color(self.current_state))
end

function integration_test_runner:_get_test_state_color(test_state)
  if test_state == test_states.none then
    return colors.white
  elseif test_state == test_states.running then
    return colors.white
  elseif test_state == test_states.success then
    return colors.green
  elseif test_state == test_states.failure then
    return colors.red
  else  -- test_state == test_states.timeout then
    return colors.dark_purple
  end
end

function integration_test_runner:_init()
  -- use simulated input during itests
  input.mode = input_modes.simulated

  -- all itests should only print itest logs
  for category in pairs(debug.active_categories) do
    local value
    if category == 'itest' then
      value = true
    else
      value = false
    end
    debug.active_categories[category] = value
  end

  self.initialized = true
end

function integration_test_runner:_check_next_action()
  assert(self._next_action_index <= #self.current_test.action_sequence, "self._next_action_index ("..self._next_action_index..") is out of bounds for self.current_test.action_sequence (size "..#self.current_test.action_sequence..")")

  -- check if next action should be applied
  local next_action = self.current_test.action_sequence[self._next_action_index]
  local should_trigger_next_action = next_action.trigger:_check(self.current_frame - self._last_trigger_frame)
  if should_trigger_next_action then
    -- apply next action and update time/index
    next_action.callback()
    self._last_trigger_frame = self.current_frame
    self._next_action_index = self._next_action_index + 1
    self:_check_end()
  end
end

function integration_test_runner:_check_end()
  -- check if last action was applied, end now
  -- this means you can define an 'end' action just by adding an empty action at the end
  if self._next_action_index > #self.current_test.action_sequence then
    self:_end_with_final_assertion()
    return true
  end
  return false
end

function integration_test_runner:_end_with_final_assertion()
  -- check the final assertion so we know if we should end with success or failure
  result, message = self.current_test:_check_final_assertion()
  if result then
    self.current_state = test_states.success
  else
    self.current_state = test_states.failure
    self.current_message = message
  end
end

-- stop the current test and reset all values
-- this is different from ending the test properly via update
-- in particular, you won't be able to retrieve the test result
function integration_test_runner:stop()
  self.current_test = nil
  self.current_frame = 0
  self._last_trigger_frame = 0
  self._next_action_index = 1
  self.current_state = test_states.none
end

-- time trigger struct
time_trigger = new_class()

-- parameters
-- frames      int   number of frames to wait before running callback after last trigger (defined from float time in s)
function time_trigger:_init(time)
  self.frames = flr(time * fps)
end

function time_trigger:_tostring()
  return "time_trigger("..self.frames..")"
end

function time_trigger.__eq(lhs, rhs)
  return lhs.frames == rhs.frames
end

-- return true if the trigger condition is verified in this context
-- else return false
-- elapsed_frames     int   number of frames elapsed since the last trigger
function time_trigger:_check(elapsed_frames)
  return elapsed_frames >= self.frames
end


-- scripted action struct
scripted_action = new_class()

-- parameters
-- trigger           trigger             trigger that will run the callback
-- callback          function            callback called on trigger
-- name              string | nil        optional name for debugging
function scripted_action:_init(trigger, callback, name)
  self.trigger = trigger
  self.callback = callback
  self.name = name or "unnamed"
end

function scripted_action:_tostring()
  return "[scripted_action ".."'"..self.name.."' ".."@ "..self.trigger.."]"
end


-- integration test class
integration_test = new_class()

-- parameters
-- name               string                         test name
-- setup              function                       setup callback - called on test start
-- action_sequence    [scripted_action]              sequence of scripted actions - run during test
-- final_assertion    function () => (bool, string)  assertion function that returns (assertion passed, error message if failed) - called on test end
-- timeout_frames     int                            number of frames before timeout (0 for no timeout, if you know the time triggers will do the job)
function integration_test:_init(name)
  self.name = name
  self.setup = nil
  self.action_sequence = {}
  self.final_assertion = nil
  self.timeout_frames = 0
end

function integration_test:_tostring()
  return "[integration_test '"..self.name.."']"
end

function integration_test:add_action(trigger, callback, name)
  assert(trigger ~= nil, "integration_test:add_action: passed trigger is nil")
  assert(callback ~= nil, "integration_test:add_action: passed callback is nil")
  add(self.action_sequence, scripted_action(trigger, callback, name))
end

-- set the timeout with a time parameter in s
function integration_test:set_timeout(time)
  self.timeout_frames = flr(time * fps)
end

-- return true if the test has timed out at given frame
function integration_test:check_timeout(frame)
  return self.timeout_frames > 0 and frame >= self.timeout_frames
end

-- return true if final assertion passes, (false, error message) else
function integration_test:_check_final_assertion()
  if self.final_assertion then
    return self.final_assertion()
  else
   return true
  end
end
