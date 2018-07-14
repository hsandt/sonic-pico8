require("bustedhelper")
require("engine/test/integrationtest")
require("engine/core/helper")

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
    integration_test_runner:stop()
  end)

  describe('start', function ()

    setup(function ()
      test = integration_test('character walks')
      test.setup = spy.new(function () end)
      spy.on(integration_test_runner, "check_end")
    end)

    teardown(function ()
      test.setup = nil
      integration_test_runner.check_end:revert()
    end)

    after_each(function ()
      test.setup:clear()
      integration_test_runner.check_end:clear()
    end)

    it('should set the current test to the passed test', function ()
      integration_test_runner:start(test)
      assert.are_equal(test, integration_test_runner.current_test)
    end)

    it('should initialize state vars', function ()
      integration_test_runner:start(test)
      assert.are_same({0., 0., 1}, {
        integration_test_runner.current_time,
        integration_test_runner.last_trigger_time,
        integration_test_runner.next_action_index
      })
    end)

    it('should call the test setup callback', function ()
      integration_test_runner:start(test)
      assert.spy(test.setup).was_called(1)
      assert.spy(test.setup).was_called_with(test)
    end)

    it('should call check_end', function ()
      integration_test_runner:start(test)
      assert.spy(integration_test_runner.check_end).was_called(1)
      assert.spy(integration_test_runner.check_end).was_called_with(match.is_ref(integration_test_runner))
    end)

    describe('(after a first start)', function ()

      local action_callback

      setup(function ()
        test:add_action(time_trigger(1.0), function () end, 'restart_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      before_each(function ()
        integration_test_runner:start(test)
        repeat_callback(1.0, function ()
          integration_test_runner:update()
        end)
      end)

      it('should automatically stop before restarting, effectively resetting state vars', function ()
        integration_test_runner:start(test)
        assert.are_same({0., 0., 1, test_result.none}, {
          integration_test_runner.current_time,
          integration_test_runner.last_trigger_time,
          integration_test_runner.next_action_index,
          integration_test_runner.current_result
        })
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
        test:add_action(time_trigger(1.01), action_callback, 'update_test_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      before_each(function ()
        integration_test_runner:start(test)
      end)

      it('should advance the current time by delta_time', function ()
        integration_test_runner:update()
        assert.are_equal(delta_time, integration_test_runner.current_time)
      end)

      it('should call an initial action (t=0.) immediately, preserving last trigger time to 0 and incrementing the next_action_index', function ()
        integration_test_runner:update()
        assert.spy(action_callback).was_called(0)
        assert.are_equal(0., integration_test_runner.last_trigger_time)
        assert.are_equal(1, integration_test_runner.next_action_index)
      end)

      it('should not call a later action (t=1.01) before the expected time (1.0s)', function ()
        repeat_callback(1.0, function ()
          integration_test_runner:update()
        end)
        assert.spy(action_callback).was_called(0)
        assert.are_equal(0., integration_test_runner.last_trigger_time)
        assert.are_equal(1, integration_test_runner.next_action_index)
      end)

      it('should call a later action (t=1.01) after the action time has been reached', function ()
        repeat_callback(1.01, function ()
          integration_test_runner:update()
        end)
        assert.spy(action_callback).was_called(1)
        assert.are_equal(1.01, integration_test_runner.last_trigger_time)
        assert.are_equal(2, integration_test_runner.next_action_index)
      end)

      it('should end the test once the last action has been applied', function ()
        repeat_callback(1.01, function ()
          integration_test_runner:update()
        end)
        assert.are_equal(test_result.success, integration_test_runner.current_result)
        assert.are_equal(2, integration_test_runner.next_action_index)
      end)

    end)

    describe('(after test ended)', function ()

      before_each(function ()
        -- without any action, start should end the test immediately
        integration_test_runner:start(test)
      end)

      it('should do nothing', function ()
        assert.are_equal(integration_test_runner.current_result, test_result.success)
        assert.has_no_errors(function () integration_test_runner:update() end)
        assert.are_equal(integration_test_runner.current_result, test_result.success)
      end)

    end)

  end)

  describe('check_end', function ()

    before_each(function ()
      integration_test_runner:start(test)
    end)

    describe('(when no actions left)', function ()

      describe('(when no final assertion)', function ()

        it('should end immediately with success', function ()
          integration_test_runner:check_end(test)
          assert.are_equal(test_result.success, integration_test_runner.current_result)
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

        it('should check the final assertion immediately and end with success', function ()
          integration_test_runner:check_end(test)
          assert.are_equal(test_result.success, integration_test_runner.current_result)
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

        it('should check the final assertion immediately and end with failure', function ()
          integration_test_runner:check_end(test)
          assert.are_equal(test_result.failure, integration_test_runner.current_result)
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

      it('should do nothing', function ()
        assert.has_no_errors(function() integration_test_runner:check_end(test) end)
      end)

    end)

    it('should reset the current test', function ()
      integration_test_runner:stop(test)
      assert.is_nil(integration_test_runner.current_test)
    end)

    it('should reset state vars', function ()
      integration_test_runner:stop(test)
      assert.are_same({0., 0., 1, test_result.none}, {
        integration_test_runner.current_time,
        integration_test_runner.last_trigger_time,
        integration_test_runner.next_action_index,
        integration_test_runner.current_result
      })
    end)

  end)

  describe('end_with_final_assertion', function ()

    before_each(function ()
      integration_test_runner:start(test)
    end)

    describe('(when no final assertion)', function ()

      it('should end with success', function ()
        integration_test_runner:end_with_final_assertion(test)
        assert.are_equal(test_result.success, integration_test_runner.current_result)
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
        integration_test_runner:check_end(test)
        assert.are_equal(test_result.success, integration_test_runner.current_result)
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
        integration_test_runner:check_end(test)
        assert.are_equal(test_result.failure, integration_test_runner.current_result)
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
        assert.has_no_errors(function() integration_test_runner:check_end(test) end)
      end)

    end)

    it('should reset the current test', function ()
      integration_test_runner:stop(test)
      assert.is_nil(integration_test_runner.current_test)
    end)

    it('should reset state vars', function ()
      integration_test_runner:stop(test)
      assert.are_same({0., 0., 1, test_result.none}, {
        integration_test_runner.current_time,
        integration_test_runner.last_trigger_time,
        integration_test_runner.next_action_index,
        integration_test_runner.current_result
      })
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
      assert.are_same({0., 0., 1, test_result.none}, {
        integration_test_runner.current_time,
        integration_test_runner.last_trigger_time,
        integration_test_runner.next_action_index,
        integration_test_runner.current_result
      })
    end)

  end)

end)

describe('time_trigger', function ()

  describe('_init', function ()
    it('should create a time trigger with a time', function ()
      local time_t = time_trigger(1.0)
      assert.is_not_nil(time_t)
      assert.are_equal(time_t.time, 1.0)
    end)
  end)

  describe('_tostring', function ()
    it('should return "time_trigger({self.time})"', function ()
      assert.are_equal("time_trigger(2.0)", time_trigger(2.0):_tostring())
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

  describe('check', function ()
    it('should return (true, late_time) if elapsed time is equal to {self.time}', function ()
      checked, late_time = time_trigger(2.0):check(2.0)
      assert.are_same({true, 0.0}, {checked, late_time})
    end)
    it('should return (true, late_time) if elapsed time is greater than {self.time}', function ()
      checked, late_time = time_trigger(2.0):check(2.2)
      assert.is_true(checked)
      assert.is_true(almost_eq_with_message(0.2, late_time))
    end)
    it('should return false if elapsed time is less than {self.time}', function ()
      assert.is_false(time_trigger(2.0):check(1.9))
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
      assert.are_equal("[scripted_action 'unnamed' @ time_trigger(2.0)]", act:_tostring())
    end)
    it('should return "scripted_action \'{self.name}\' @ {self.trigger}" if some name', function ()
      local act = scripted_action(time_trigger(2.0), function () end, 'do_something')
      assert.are_equal("[scripted_action 'do_something' @ time_trigger(2.0)]", act:_tostring())
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

  describe('check_final_assertion', function ()
    it('should call the final assertion and return the result', function ()
      local test = integration_test('character follows ground', function () end)
      test.final_assertion = function()
        return false, 'error message'
      end
      assert.are_same({false, 'error message'}, {test:check_final_assertion()})
    end)
  end)

end)
