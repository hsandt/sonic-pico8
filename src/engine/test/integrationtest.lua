require("engine/application/constants")
require("engine/core/class")
require("engine/test/assertions")
local debug = require("engine/debug/debug")
local input = require("engine/input/input")

-- deactivate input completely during itests
input.active = false

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

test_result = {
  none    = 'none',       -- no test started or the test is not over yet
  success = 'success',    -- the test has just succeeded
  failure = 'failure'     -- the test has just failed
}

-- integration test runner singleton
integration_test_runner = singleton {
  current_test = nil,
  current_time = 0.,
  last_trigger_time = 0.,
  next_action_index = 1,
  current_result = test_result.none
}

function integration_test_runner:start(test)
  if self.current_test then
    self:stop()
  end
  self.current_test = test
  if test.setup then
    test:setup()
  end
  self:check_end()
end

function integration_test_runner:update()
  assert(self.current_test, "integration_test_runner:update: current_test is not set")
  if self.current_result ~= test_result.none then
    -- the current test is over and we already got the result
    -- do nothing and fail silently (to avoid crashing just because we repeated update a bit too much)
    return
  end

  -- advance time
  self.current_time = self.current_time + delta_time
  -- check if next action should be applied
  local next_action = self.current_test.action_sequence[self.next_action_index]
  should_trigger_next_action, late_time = next_action.trigger:check(self.current_time - self.last_trigger_time)
  if should_trigger_next_action then
    -- apply next action and update time/index
    next_action.callback()
    self.last_trigger_time = self.current_time - late_time
    self.next_action_index = self.next_action_index + 1

    self:check_end()
  end

end

function integration_test_runner:check_end()
  -- check if last action was applied, end now
  -- this means you can define an 'end' action just by adding an empty action at the end
  if self.next_action_index > #self.current_test.action_sequence then
    self:end_with_final_assertion()
  end
end

function integration_test_runner:end_with_final_assertion()
  -- check the final assertion so we know if we should end with success or failure
  result, message = self.current_test:check_final_assertion()
  if result then
    self.current_result = test_result.success
    log("itest '"..self.current_test.name.."': final assertion succeeded", "itest")
  else
    self.current_result = test_result.failure
    log("itest '"..self.current_test.name.."': final assertion failed: "..message, "itest")
  end
end

-- stop the current test and reset all values
-- this is different from ending the test properly via update
-- in particular, you won't be able to retrieve the test result
function integration_test_runner:stop()
  self.current_test = nil
  self.current_time = 0.
  self.last_trigger_time = 0.
  self.next_action_index = 1
  self.current_result = test_result.none
end

-- time trigger struct
time_trigger = new_class()

-- parameters
-- time              number (float)      relative time to run callback since last trigger
function time_trigger:_init(time)
  self.time = time
end

function time_trigger:_tostring()
  return "time_trigger("..self.time..")"
end

function time_trigger.__eq(lhs, rhs)
  return lhs.time == rhs.time
end

-- return (true, late_time) if the trigger condition is verified in this context
--  where late_time is the estimated time since the trigger condition was actually verified
--  (it should be less than delta_time and just a way to catch back a little when a time was not a multiple of fps)
-- else return (false, nil)
-- elapsed time     number (float)    time elapsed since the last trigger
function time_trigger:check(elapsed_time)
  time_diff = elapsed_time - self.time
  if time_diff >= 0 then
    return true, time_diff
  else
    return false
  end
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
function integration_test:_init(name)
  self.name = name
  self.setup = nil
  self.action_sequence = {}
  self.final_assertion = nil
end

function integration_test:_tostring()
  return "[integration_test '"..self.name.."']"
end

function integration_test:add_action(trigger, callback, name)
  assert(trigger ~= nil, "integration_test:add_action: passed trigger is nil")
  assert(callback ~= nil, "integration_test:add_action: passed callback is nil")
  add(self.action_sequence, scripted_action(trigger, callback, name))
end

-- return true if final assertion passes, (false, error message) else
function integration_test:check_final_assertion()
  if self.final_assertion then
    return self.final_assertion()
  else
   return true
  end
end
