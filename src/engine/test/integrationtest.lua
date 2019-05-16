require("engine/application/constants")
require("engine/core/class")
require("engine/render/color")
require("engine/test/assertions")
--#if log
local logging = require("engine/debug/logging")
--#endif
local input = require("engine/input/input")

local mod = {}

test_states = {
  none = 'none',          -- no test started
  running = 'running',    -- the test is still running
  success = 'success',    -- the test has just succeeded
  failure = 'failure',    -- the test has just failed
  timeout = 'timeout'     -- the test has timed out
}

-- integration test manager: registers all itests
-- itests   {string: itest}  registered itests, indexed by name
itest_manager = singleton(function (self)
  self.itests = {}
end)
mod.itest_manager = itest_manager

-- all-in-one utility function that creates and register a new itest,
-- defining setup, actions and final assertion inside a contextual callback,
-- as in the describe-it pattern
-- name        string        itest name
-- states      {gamestates}  sequence of non-dummy gamestates used for the itest
-- definition  function      definition callback

-- definition example:
--   function ()
--     setup(function ()
--       -- setup test
--     end)
--     add_action(time_trigger(1.0), function ()
--       -- change character intention
--     end)
--     add_action(time_trigger(0.5), function ()
--       -- more actions
--     end)
--     final_assert(function ()
--       return -- true if everything is as expected
--     end)
--   end)
function itest_manager:register_itest(name, states, definition)
  local itest = mod.integration_test(name, states)
  self:register(itest)

  -- context
  -- last time trigger
  local last_time_trigger = nil

  -- we are defining global functions capturing local variables, which is bad
  --  but it's acceptable to have them accessible inside the definition callback
  --  (as getfenv/setfenv cannot be implemented in pico8 due to missing debug.getupvalue)
  -- actually they would be callable even after calling register_itest as they "leak"
  -- later, we'll build a full dsl parser that will not require such functions


  -- don't name setup, busted would hide this name
  function setup_callback(callback)
    itest.setup = callback
  end

  function add_action(trigger, callback, name)
    itest:add_action(trigger, callback, name)
  end

  function wait(time, use_frame_unit)
    if last_time_trigger then
      -- we were already waiting, so finish last wait with empty action
      itest:add_action(last_time_trigger, nil)
    end
    last_time_trigger = mod.time_trigger(time, use_frame_unit)
  end

  function act(callback)
    if last_time_trigger then
      itest:add_action(last_time_trigger, callback)
      last_time_trigger = nil  -- consume so we know no final wait-action is needed
    else
      -- no wait since last action (or this is the first action), so use immediate trigger
      itest:add_action(mod.immediate_trigger, callback)
    end
  end

  function final_assert(callback)
    itest.final_assertion = callback
  end

  definition()

  -- if we finished with a wait (with or without final assertion),
  --  we need to close the itest with a wait-action
  if last_time_trigger then
    itest:add_action(last_time_trigger, nil)
  end
end

-- register a created itest instance
-- you can add actions and final assertion later
function itest_manager:register(itest)
  add(self.itests, itest)
end

-- proxy method for itest runner helper method
function itest_manager:init_game_and_start_by_index(index)
  local itest = self.itests[index]
  assert(itest, "itest_manager:init_game_and_start_by_index: index is "..tostr(index).." but only "..tostr(#self.itests).." were registered.")
  itest_runner:init_game_and_start(itest)
end

-- integration test runner singleton
-- usage:
-- first, make sure you have registered itests via the itest_manager
--   and that you are running an itest via itest_manager:init_game_and_start_by_index (a proxy for itest_runner:init_game_and_start)
-- in _init, create a game app, set its initial_gamestate and set itest_runner.app to this app instance
-- in _update(60), call itest_runner:update_game_and_test
-- in _draw, call itest_runner:draw_game_and_test

-- attributes
-- initialized          bool              true if it has already been initialized.
--                                        initialization is lazy and is only needed once
-- current_test         integration_test  current itest being run
-- current_frame        int               index of the current frame run
-- _last_trigger_frame  int               stored index of the frame where the last command trigger was received
-- _next_action_index   int               index of the next action to execute in the action list
-- current_state        test_states       stores if test has not started, is still running or has succeeded/failed
-- current_message      string            failure message, nil if test has not failed
-- app                  gameapp           gameapp instance of the tested game
--                                        must be set directly with itest_runner.app = ...

-- a test's lifetime follows the phases:
-- none -> running -> success/failure/timeout (still alive, but not updated)
--  -> stopped when a another test starts running
itest_runner = singleton(function (self)
  self.initialized = false
  self.current_test = nil
  self.current_frame = 0
  self._last_trigger_frame = 0
  self._next_action_index = 1
  self.current_state = test_states.none
  self.current_message = nil
  self.app = nil
end)

-- helper method to use in rendered itest _init
function itest_runner:init_game_and_start(test)
  assert(self.app ~= nil, "itest_runner:init_game_and_start: self.app is not set")

  -- if there was a previous test, app was initialized too, so reset both now
  -- (in reverse order of start)
  if self.current_test then
    self:stop()
    self.app:reset()
  end

  self.app:start()
  itest_runner:start(test)
end

-- helper method to use in rendered itest _update60
function itest_runner:update_game_and_test()
  if self.current_state == test_states.running then

    -- update app, then test runner
    -- updating test runner 2nd allows us to check the actual game state at final frame f,
    --  after everything has been computed
    -- time_trigger(0.)  initial actions will still be applied before first frame
    --  thanks to the initial _check_next_action on start, but setup is still recommended
    log("frame #"..self.current_frame + 1, "trace")
    self.app:update()
    self:update()
    if self.current_state ~= test_states.running then
      log("itest '"..self.current_test.name.."' ended with "..self.current_state, "itest")
      if self.current_state == test_states.failure then
        log("failed: "..self.current_message, "itest")
      end
    end
  end
end

-- helper method to use in rendered itest _draw
function itest_runner:draw_game_and_test()
  self.app:draw()
  self:draw()
end

-- start a test: integration_test
function itest_runner:start(test)
  -- lazy initialization
  if not self.initialized then
    self:_initialize()
  end

  -- log after _initialize which sets up the logger
  log("starting itest: "..test.name, "trace")

  self.current_test = test
  self.current_state = test_states.running

  if test.setup then
    test.setup()
  end

  -- edge case: 0 actions in the action sequence. check end
  -- immediately to avoid out of bounds index in _check_next_action
  if not self:_check_end() then
    self:_check_next_action()
  end
end

function itest_runner:update()
  assert(self.current_test, "itest_runner:update: current_test is not set")
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

function itest_runner:draw()
  if self.current_test then
    api.print(self.current_test.name, 2, 2, colors.yellow)
    api.print(self.current_state, 2, 9, self:_get_test_state_color(self.current_state))
  else
    api.print("no itest running", 8, 8, colors.white)
  end
end

function itest_runner:_get_test_state_color(test_state)
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

function itest_runner:_initialize()
  -- use simulated input during itests
  input.mode = input_modes.simulated

--#if log
  -- all itests should only print itest logs, and maybe trace if you want
  logging.logger:deactivate_all_categories()
  logging.logger.active_categories["itest"] = true
  logging.logger.active_categories["trace"] = false
--#endif

  self.initialized = true
end

function itest_runner:_check_next_action()
  assert(self._next_action_index <= #self.current_test.action_sequence, "self._next_action_index ("..self._next_action_index..") is out of bounds for self.current_test.action_sequence (size "..#self.current_test.action_sequence..")")

  -- test: chain actions with no intervals between them
  local should_trigger_next_action
  repeat
  -- check if next action should be applied
  local next_action = self.current_test.action_sequence[self._next_action_index]
  local should_trigger_next_action = next_action.trigger:_check(self.current_frame - self._last_trigger_frame)
  if should_trigger_next_action then
    -- apply next action and update time/index, unless nil (useful to just wait before itest end and final assertion)
    if next_action.callback then
      next_action.callback()
    end
    self._last_trigger_frame = self.current_frame
    self._next_action_index = self._next_action_index + 1
      if self:_check_end() then
        break
      end
  end
  until not should_trigger_next_action
end

function itest_runner:_check_end()
  -- check if last action was applied, end now
  -- this means you can define an 'end' action just by adding an empty action at the end
  if self.current_test.action_sequence[1] then
  end
  if self._next_action_index > #self.current_test.action_sequence then
    self:_end_with_final_assertion()
    return true
  end
  return false
end

function itest_runner:_end_with_final_assertion()
  -- check the final assertion so we know if we should end with success or failure
  result, message = self.current_test:_check_final_assertion()
  if result then
    self.current_state = test_states.success
  else
    self.current_state = test_states.failure
    self.current_message = message
  end
end

-- stop the current test, tear it down and reset all values
-- this is only called when starting a new test, not when it finished,
--  so we can still access info on the current test while the user examines its result
function itest_runner:stop()
  if self.current_test.teardown then
    self.current_test.teardown()
  end

  self.current_test = nil
  self.current_frame = 0
  self._last_trigger_frame = 0
  self._next_action_index = 1
  self.current_state = test_states.none
end

-- time trigger struct
local time_trigger = new_struct()
mod.time_trigger = time_trigger

-- non-member parameters
-- time            float time to wait before running callback after last trigger (in seconds by default, in frames if use_frame_unit is true)
-- use_frame_unit  bool  if true, count the time in frames instead of seconds
-- members
-- frames          int   number of frames to wait before running callback after last trigger (defined from float time in s)
function time_trigger:_init(time, use_frame_unit)
  if use_frame_unit then
    self.frames = time
  else
    self.frames = flr(time * fps)
  end
end

--#if log
function time_trigger:_tostring()
  return "time_trigger("..self.frames..")"
end
--#endif

-- return true if the trigger condition is verified in this context
-- else return false
-- elapsed_frames     int   number of frames elapsed since the last trigger
function time_trigger:_check(elapsed_frames)
  return elapsed_frames >= self.frames
end

-- helper triggers
mod.immediate_trigger = time_trigger(0, true)


-- scripted action struct (but we use class because comparing functions only work by reference)
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

--#if log
function scripted_action:_tostring()
  return "[scripted_action ".."'"..self.name.."' ".."@ "..self.trigger.."]"
end
--#endif


-- integration test class
local integration_test = new_class()
mod.integration_test = integration_test

-- parameters
-- name               string                         test name
-- setup              function                       setup callback - called on test start (pure function)
-- teardown           function                       teardown callback - called on test finish (pure function)
-- action_sequence    [scripted_action]              sequence of scripted actions - run during test
-- final_assertion    function () => (bool, string)  assertion function that returns (assertion passed, error message if failed) - called on test end
-- timeout_frames     int                            number of frames before timeout (0 for no timeout, if you know the time triggers will do the job)
-- active_gamestates  [gamestate.types]              (non-pico8 only) sequence of gamestate modules to require for that itest.
--                                                    must be the same as in itest script first line
--                                                    and true gamestate modules should be required accordingly if directly referenced
function integration_test:_init(name, active_gamestates)
  self.name = name
  self.setup = nil
  self.teardown = nil
  self.action_sequence = {}
  self.final_assertion = nil
  self.timeout_frames = 0
--#ifn pico8
 assert(active_gamestates, "integration_test._init: non-pico8 build requires active_gamestates to define them at runtime")
 self.active_gamestates = active_gamestates
--#endif
end

--#if log
function integration_test:_tostring()
  return "[integration_test '"..self.name.."']"
end
--#endif

-- add an action to the action sequence. nil callback is acceptable, it acts like an empty function.
function integration_test:add_action(trigger, callback, name)
  assert(trigger ~= nil, "integration_test:add_action: passed trigger is nil")
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

return mod
