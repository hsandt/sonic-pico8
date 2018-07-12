require("bustedhelper")
require("engine/test/integrationtest")
require("engine/core/helper")

function repeat_update(time, update_callback)
  for i = 1, time*fps do
   update_callback()
  end
end

describe('integration_test_runner', function ()

  local test

  setup(function ()
    test = integration_test('character walks')
    test.setup = spy.new(function () end)
  end)

  after_each(function ()
    integration_test_runner:stop()
    test.setup:clear()
  end)

  describe('start', function ()

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
    end)

    it('should end immediately when there are no actions', function ()
      integration_test_runner:start(test)
      assert.are_equal(test_result.success, integration_test_runner.current_result)
    end)

    describe('start', function ()

      setup(function ()
        test:add_action(time_trigger(0.0), function () end, 'start_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      it('should not end immediately when there are some actions (even at t=0.)', function ()
        integration_test_runner:start(test)
        assert.are_equal(test_result.none, integration_test_runner.current_result)
      end)

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
        repeat_update(1.0, function ()
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
        test:add_action(time_trigger(1.0), action_callback, 'update_test_action')
      end)

      teardown(function ()
        clear_table(test.action_sequence)
      end)

      before_each(function ()
        integration_test_runner:start(test)
      end)

      it('should call an initial action (t=0.) immediately', function ()
        integration_test_runner:update()
        assert.spy(action_callback).was_called(0)
      end)
      it('should not call a later action (t=1.) before the expected time (1.0s)', function ()
        repeat_update(0.9, function ()
          integration_test_runner:update()
        end)
        assert.spy(action_callback).was_called(0)
      end)
      it('should call a later action (t=1.) after the action time has been reached', function ()
        repeat_update(1.0, function ()
          integration_test_runner:update()
        end)
        assert.spy(action_callback).was_called(1)
      end)
      it('should end the test once the last action has been applied', function ()
        repeat_update(1.0, function ()
          integration_test_runner:update()
        end)
        assert.are_equal(test_result.success, integration_test_runner.current_result)
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

end)
