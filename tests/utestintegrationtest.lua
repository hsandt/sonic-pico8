require("bustedhelper")
require("engine/test/integrationtest")
require("engine/core/helper")
require("engine/render/color")
local debug = require("engine/debug/debug")
local gameapp = require("game/application/gameapp")
local input = require("engine/input/input")

local function repeat_callback(time, callback)
  -- ceil is just for times with precision of 0.01 or deeper,
  -- so the last frame is reached (e.g. an action at t=0.01 is applied)
  -- caution: this may make fractional times advance too much and apply actions they shouldn't,
  -- so tune your times carefully for testing
  for i = 1, ceil(time*fps) do
   callback()
  end
end

describe('integration_test_runner', function ()

  local test

  setup(function ()
    test = integration_test('character walks')
  end)

  after_each(function ()
    -- full reset
    integration_test_runner.initialized = false
    integration_test_runner.current_test = nil
    integration_test_runner.current_frame = 0.
    integration_test_runner._last_trigger_frame = 0.
    integration_test_runner._next_action_index = 1
    integration_test_runner.current_state = test_states.none

    input.mode = input_modes.native

    debug.active_categories = {
      default = true,
      flow = true,
      player = true,
      ui = true,
      codetuner = true,
      itest = true
    }
  end)

  describe('init_game_and_start', function ()

    setup(function ()
      gameapp_init_stub = stub(gameapp, "init")
      itest_runner_start_stub = stub(integration_test_runner, "start")
    end)

    teardown(function ()
      gameapp_init_stub:revert()
      itest_runner_start_stub:revert()
    end)

    after_each(function ()
      gameapp_init_stub:clear()
      itest_runner_start_stub:clear()
    end)

    it('should init the gameapp and the passed test', function ()
      integration_test_runner:init_game_and_start(test)
      assert.spy(gameapp_init_stub).was_called(1)
      assert.spy(gameapp_init_stub).was_called_with()
      assert.spy(itest_runner_start_stub).was_called(1)
      assert.spy(itest_runner_start_stub).was_called_with(match.is_ref(integration_test_runner), test)
    end)

  end)

  describe('update_game_and_test', function ()

    setup(function ()
      gameapp_update_stub = stub(gameapp, "update")
      spy.on(integration_test_runner, "update")
    end)

    teardown(function ()
      gameapp_update_stub:revert()
      integration_test_runner.update:revert()
    end)

    after_each(function ()
      gameapp_update_stub:clear()
      integration_test_runner.update:clear()
    end)

    describe('(when state is not running)', function ()

      it('should do nothing', function ()
        integration_test_runner:update_game_and_test()
        assert.spy(gameapp_update_stub).was_called(0)
        assert.spy(integration_test_runner.update).was_called(0)
      end)

    end)

    describe('(when state is running for some actions)', function ()

      setup(function ()
        test:add_action(time_trigger(1.0), function () end, 'some_action')
        integration_test_runner:start(test)
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      it('should update the gameapp and the passed test', function ()
        integration_test_runner:update_game_and_test()
        assert.spy(gameapp_update_stub).was_called(1)
        assert.spy(gameapp_update_stub).was_called_with()
        assert.spy(integration_test_runner.update).was_called(1)
        assert.spy(integration_test_runner.update).was_called_with(match.is_ref(integration_test_runner))
      end)

    end)

    describe('(when test ends on this update)', function ()

      local log_stub

      setup(function ()
        test:add_action(time_trigger(0.017), function () end, 'some_action')
        integration_test_runner:start(test)
        log_stub = stub(_G, "log")
      end)

      teardown(function ()
        clear_table(test.action_sequence)
        log_stub:revert()
      end)

      after_each(function ()
        log_stub:clear()
      end)

      it('should also log the result', function ()
        integration_test_runner:update_game_and_test()
        assert.spy(log_stub).was_called(1)
      end)

    end)

  end)

  describe('draw_game_and_test', function ()

    setup(function ()
      gameapp_draw_stub = stub(gameapp, "draw")
      itest_runner_draw_stub = stub(integration_test_runner, "draw")
    end)

    teardown(function ()
      gameapp_draw_stub:revert()
      itest_runner_draw_stub:revert()
    end)

    after_each(function ()
      gameapp_draw_stub:clear()
      itest_runner_draw_stub:clear()
    end)

    it('should draw the gameapp and the passed test information', function ()
      integration_test_runner:draw_game_and_test()
      assert.spy(gameapp_draw_stub).was_called(1)
      assert.spy(gameapp_draw_stub).was_called_with()
      assert.spy(itest_runner_draw_stub).was_called(1)
      assert.spy(itest_runner_draw_stub).was_called_with(match.is_ref(integration_test_runner))
    end)

  end)

  describe('start', function ()

    setup(function ()
      test.setup = spy.new(function () end)
      spy.on(integration_test_runner, "_init")
      spy.on(integration_test_runner, "_check_end")
      spy.on(integration_test_runner, "_check_next_action")
    end)

    teardown(function ()
      test.setup = nil
      integration_test_runner._init:revert()
      integration_test_runner._check_end:revert()
      integration_test_runner._check_next_action:revert()
    end)

    after_each(function ()
      test.setup:clear()
      integration_test_runner._init:clear()
      integration_test_runner._check_end:clear()
      integration_test_runner._check_next_action:clear()
    end)

    it('should set the current test to the passed test', function ()
      integration_test_runner:start(test)
      assert.are_equal(test, integration_test_runner.current_test)
    end)

    it('should initialize state vars', function ()
      integration_test_runner:start(test)
      assert.are_same({0, 0, 1}, {
        integration_test_runner.current_frame,
        integration_test_runner._last_trigger_frame,
        integration_test_runner._next_action_index
      })
    end)

    it('should call the test setup callback', function ()
      integration_test_runner:start(test)
      assert.spy(test.setup).was_called(1)
      assert.spy(test.setup).was_called_with(test)
    end)

    it('should call _init the first time', function ()
      integration_test_runner:start(test)
      assert.spy(integration_test_runner._init).was_called(1)
      assert.spy(integration_test_runner._init).was_called_with(match.is_ref(integration_test_runner))
    end)

    it('should call _check_end', function ()
      integration_test_runner:start(test)
      assert.spy(integration_test_runner._check_end).was_called(1)
      assert.spy(integration_test_runner._check_end).was_called_with(match.is_ref(integration_test_runner))
    end)

    describe('(when no actions)', function ()

      it('should not check the next action', function ()
        integration_test_runner:start(test)
        assert.spy(integration_test_runner._check_next_action).was_called(0)
      end)

      it('should immediately end the run (result depends on final assertion)', function ()
        integration_test_runner:start(test)
        assert.are_not_equal(test_states.running, integration_test_runner.current_state)
      end)

    end)

    describe('(when some actions)', function ()

      setup(function ()
        test:add_action(time_trigger(1.0), function () end, 'some_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      it('should check the next action immediately (if at time 0, will also call it)', function ()
        integration_test_runner:start(test)
        assert.spy(integration_test_runner._check_next_action).was_called(1)
        assert.spy(integration_test_runner._check_next_action).was_called_with(match.is_ref(integration_test_runner))
      end)

      it('should enter running state', function ()
        integration_test_runner:start(test)
        assert.are_equal(test_states.running, integration_test_runner.current_state)
      end)

    end)

    describe('(after a first start)', function ()

      setup(function ()
        test:add_action(time_trigger(1.0), function () end, 'restart_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      before_each(function ()
        -- some progress
        integration_test_runner:start(test)
        repeat_callback(1.0, function ()
          integration_test_runner:update()
        end)
      end)

      it('should automatically stop before restarting, effectively resetting state vars but the current test and state', function ()
        integration_test_runner:start(test)
        assert.are_same({0, 0, 1, test_states.running}, {
          integration_test_runner.current_frame,
          integration_test_runner._last_trigger_frame,
          integration_test_runner._next_action_index,
          integration_test_runner.current_state
        })
      end)

      it('should not call _init the second time', function ()
        -- in this specific case, start was called in before_each so we need to clear manually
        -- just before we call start ourselves to have the correct count
        integration_test_runner._init:clear()
        integration_test_runner:start(test)
        assert.spy(integration_test_runner._init).was_called(0)
      end)

    end)

  end)

  describe('update', function ()

    it('should assert when no test has been started', function ()
      assert.has_error(function()
        integration_test_runner:update()
      end)
    end)

    describe('(after test started)', function ()

      local action_callback

      setup(function ()
        action_callback = spy.new(function () end)
        -- need at least 1/60=0.1666s above 1.0s so it's not called after 1.0s converted to frames
        test:add_action(time_trigger(1.02), action_callback, 'update_test_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      before_each(function ()
        integration_test_runner:start(test)
      end)

      it('should advance the current time by 1', function ()
        integration_test_runner:update()
        assert.are_equal(1, integration_test_runner.current_frame)
      end)

      it('should call an initial action (t=0.) immediately, preserving last trigger time to 0 and incrementing the _next_action_index', function ()
        integration_test_runner:update()
        assert.spy(action_callback).was_called(0)
        assert.are_equal(0., integration_test_runner._last_trigger_frame)
        assert.are_equal(1, integration_test_runner._next_action_index)
      end)

      it('should not call a later action (t=1.02) before the expected time (1.0s)', function ()
        repeat_callback(1.0, function ()
          integration_test_runner:update()
        end)
        assert.spy(action_callback).was_called(0)
        assert.are_equal(0., integration_test_runner._last_trigger_frame)
        assert.are_equal(1, integration_test_runner._next_action_index)
      end)

      it('should call a later action (t=1.02) after the action time has been reached', function ()
        repeat_callback(1.02, function ()
          integration_test_runner:update()
        end)
        assert.spy(action_callback).was_called(1)
        assert.are_equal(61, integration_test_runner._last_trigger_frame)
        assert.are_equal(2, integration_test_runner._next_action_index)
      end)

      it('should end the test once the last action has been applied', function ()
        repeat_callback(1.02, function ()
          integration_test_runner:update()
        end)
        assert.are_equal(test_states.success, integration_test_runner.current_state)
        assert.are_equal(2, integration_test_runner._next_action_index)
      end)

    end)

    describe('(after test ended)', function ()

      before_each(function ()
        -- without any action, start should end the test immediately
        integration_test_runner:start(test)
      end)

      it('should do nothing', function ()
        assert.are_equal(integration_test_runner.current_state, test_states.success)
        assert.has_no_errors(function () integration_test_runner:update() end)
        assert.are_equal(integration_test_runner.current_state, test_states.success)
      end)

    end)

  end)

  describe('draw', function ()

    it('should assert if no current test is set', function ()
      assert.has_error(function ()
        integration_test_runner:draw()
      end)
    end)

    describe('(when curent test is set)', function ()

      local api_print_stub

      setup(function ()
        integration_test_runner.current_test = test
        integration_test_runner.current_state = test_states.running
        api_print_stub = stub(api, "print")
      end)

      teardown(function ()
        api_print_stub:revert()
      end)

      after_each(function ()
        api_print_stub:clear()
      end)

      it('should draw information on the current test', function ()
        integration_test_runner:draw()
        assert.spy(api_print_stub).was_called(2)
      end)

    end)

  end)

  describe('_get_test_state_color', function ()

    it('should return white for none', function ()
      assert.are_equal(colors.white, integration_test_runner:_get_test_state_color(test_states.none))
    end)

    it('should return white for none', function ()
      assert.are_equal(colors.white, integration_test_runner:_get_test_state_color(test_states.running))
    end)

    it('should return green for success', function ()
      assert.are_equal(colors.green, integration_test_runner:_get_test_state_color(test_states.success))
    end)

    it('should return red for failure', function ()
      assert.are_equal(colors.red, integration_test_runner:_get_test_state_color(test_states.failure))
    end)

  end)

  describe('_init', function ()

    it('should set the input mode to simulated', function ()
      integration_test_runner:_init()
      assert.are_equal(input_modes.simulated, input.mode)
    end)

    it('should set all debug categories to inactive except itest', function ()
      integration_test_runner:_init()
      assert.are_same({
          default = false,
          flow = false,
          player = false,
          ui = false,
          codetuner = false,
          itest = true
        },
        debug.active_categories)
    end)

    it('should set initialized to true', function ()
      integration_test_runner:_init()
      assert.is_true(integration_test_runner.initialized)
    end)

  end)

  describe('_check_end', function ()

    before_each(function ()
      integration_test_runner:start(test)
    end)

    describe('(when no actions left)', function ()

      describe('(when no final assertion)', function ()

        it('should make test end immediately with success and return true', function ()
          local result = integration_test_runner:_check_end(test)
          assert.is_true(result)
          assert.are_same({test_states.success, nil},
            {integration_test_runner.current_state, integration_test_runner.current_message})
        end)

      end)

      describe('(when final assertion passes)', function ()

        setup(function ()
          test.final_assertion = function ()
            return true
          end
        end)

        teardown(function ()
          test.final_assertion = nil
        end)

        it('should check the final assertion immediately, end with success and return true', function ()
          local result = integration_test_runner:_check_end(test)
          assert.is_true(result)
          assert.are_same({test_states.success, nil},
            {integration_test_runner.current_state, integration_test_runner.current_message})
        end)

      end)

      describe('(when final assertion passes)', function ()

        setup(function ()
          test.final_assertion = function ()
            return false, "error message"
          end
        end)

        teardown(function ()
          test.final_assertion = nil
        end)

        it('should check the final assertion immediately, end with failure and return true', function ()
          local result = integration_test_runner:_check_end(test)
          assert.is_true(result)
          assert.are_equal(test_states.failure, integration_test_runner.current_state)
        end)

      end)

    end)

    describe('(when some actions left)', function ()

      setup(function ()
        test:add_action(time_trigger(1.0), function () end, 'check_end_test_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      it('should return false', function ()
        assert.is_false(integration_test_runner:_check_end(test))
      end)

    end)

  end)

  describe('_end_with_final_assertion', function ()

    before_each(function ()
      integration_test_runner:start(test)
    end)

    describe('(when no final assertion)', function ()

      it('should end with success', function ()
        integration_test_runner:_end_with_final_assertion(test)
        assert.are_equal(test_states.success, integration_test_runner.current_state)
      end)

    end)

    describe('(when final assertion passes)', function ()

      setup(function ()
        test.final_assertion = function ()
          return true
        end
      end)

      teardown(function ()
        test.final_assertion = nil
      end)

      it('should check the final assertion and end with success', function ()
        integration_test_runner:_check_end(test)
        assert.are_equal(test_states.success, integration_test_runner.current_state)
      end)

    end)

    describe('(when final assertion passes)', function ()

      setup(function ()
        test.final_assertion = function ()
          return false, "error message"
        end
      end)

      teardown(function ()
        test.final_assertion = nil
      end)

      it('should check the final assertion and end with failure', function ()
        integration_test_runner:_check_end(test)
        assert.are_same({test_states.failure, "error message"},
          {integration_test_runner.current_state, integration_test_runner.current_message})
      end)

    end)

    describe('(when some actions left)', function ()

      setup(function ()
        test:add_action(time_trigger(1.0), function () end, 'check_end_test_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      it('should do nothing', function ()
        assert.has_no_errors(function() integration_test_runner:_check_end(test) end)
      end)

    end)

  end)

  describe('stop', function ()

    before_each(function ()
      integration_test_runner:start(test)
    end)

    it('should reset the current test', function ()
      integration_test_runner:stop(test)
      assert.is_nil(integration_test_runner.current_test)
    end)

    it('should reset state vars', function ()
      integration_test_runner:stop(test)
      assert.are_same({0, 0, 1, test_states.none}, {
        integration_test_runner.current_frame,
        integration_test_runner._last_trigger_frame,
        integration_test_runner._next_action_index,
        integration_test_runner.current_state
      })
    end)

  end)

end)

describe('time_trigger', function ()

  describe('_init', function ()
    it('should create a time trigger with a time', function ()
      local time_t = time_trigger(1.0)
      assert.is_not_nil(time_t)
      assert.are_equal(time_t.frames, 60)
    end)
  end)

  describe('_tostring', function ()
    it('should return "time_trigger({self.time})"', function ()
      assert.are_equal("time_trigger(120)", time_trigger(2.0):_tostring())
    end)
  end)

  describe('__eq', function ()
    it('should return true if times are equal', function ()
      assert.is_true(time_trigger(2.0) == time_trigger(2.0))
    end)
    it('should return false if times are not equal', function ()
      assert.is_true(time_trigger(1.0) ~= time_trigger(2.0))
    end)
  end)

  describe('_check', function ()
    it('should return true if elapsed time is equal to {self.frames}', function ()
      assert.is_true(time_trigger(2.0):_check(120))
    end)
    it('should return true if elapsed time is greater than {self.frames}', function ()
      assert.is_true(time_trigger(2.0):_check(121))
    end)
    it('should return false if elapsed time is less than {self.frames}', function ()
      assert.is_false(time_trigger(2.0):_check(119))
    end)
  end)

end)

describe('scripted_action', function ()

  describe('_init', function ()
    it('should create a scripted action with a trigger and callback (unnamed)', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2.0), do_something)
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2.0), do_something, "unnamed"}, {act.trigger, act.callback, act.name})
    end)
    it('should create a scripted action with a trigger, callback and name', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2.0), do_something, "do_something")
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2.0), do_something, "do_something"}, {act.trigger, act.callback, act.name})
    end)
  end)

  describe('_tostring', function ()
    it('should return "scripted_action \'unnamed\' @ {self.trigger}"" if no name', function ()
      local act = scripted_action(time_trigger(2.0), function () end)
      assert.are_equal("[scripted_action 'unnamed' @ time_trigger(120)]", act:_tostring())
    end)
    it('should return "scripted_action \'{self.name}\' @ {self.trigger}" if some name', function ()
      local act = scripted_action(time_trigger(2.0), function () end, 'do_something')
      assert.are_equal("[scripted_action 'do_something' @ time_trigger(120)]", act:_tostring())
    end)
  end)
end)


describe('integration_test', function ()

  describe('_init', function ()
    it('should create an integration test with a name', function ()
      local test = integration_test('character follows ground')
      assert.is_not_nil(test)
      assert.are_same({'character follows ground', nil, {}, nil}, {test.name, test.setup, test.action_sequence, test.final_assertion})
    end)
  end)

  describe('_tostring', function ()
    it('should return "integration_test \'{self.name}\'', function ()
      local test = integration_test('character follows ground', function () end)
      assert.are_equal("[integration_test 'character follows ground']", test:_tostring())
    end)
  end)

  describe('add_action', function ()
    it('should add a scripted action in the action sequence', function ()
      local test = integration_test('character follows ground', function () end)
      action_callback = function () end
      test:add_action(time_trigger(1.0), action_callback, 'my_action')
      assert.are_equal(1, #test.action_sequence)
      assert.are_same({time_trigger(1.0), action_callback, 'my_action'}, {test.action_sequence[1].trigger, test.action_sequence[1].callback, test.action_sequence[1].name})
    end)
  end)

  describe('_check_final_assertion', function ()
    it('should call the final assertion and return the result', function ()
      local test = integration_test('character follows ground', function () end)
      test.final_assertion = function()
        return false, 'error message'
      end
      assert.are_same({false, 'error message'}, {test:_check_final_assertion()})
    end)
  end)

end)
