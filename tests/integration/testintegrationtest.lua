require("bustedhelper")
require("engine/test/integrationtest")

describe('time_trigger', function ()

  describe('_init', function ()
    it('should create a time trigger with a time', function ()
      local time_t = time_trigger(1)
      assert.is_not_nil(time_t)
      assert.are_equal(time_t.time, 1)
    end)
  end)

  describe('_tostring', function ()
    it('should return "time_trigger({self.time})"', function ()
      assert.are_equal("time_trigger(2)", time_trigger(2):_tostring())
    end)
  end)

end)

describe('scripted_action', function ()

  describe('_init', function ()
    it('should create a scripted action with a trigger and callback (unnamed)', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2), do_something)
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2), do_something, "unnamed"}, {act.trigger, act.callback, act.name})
    end)
    it('should create a scripted action with a trigger, callback and name', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2), do_something, "do_something")
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2), do_something, "do_something"}, {act.trigger, act.callback, act.name})
    end)
  end)

  describe('_tostring', function ()
    it('should return "scripted_action \'unnamed\' @ {self.trigger}"" if no name', function ()
      local act = scripted_action(time_trigger(2), function () end)
      assert.are_equal("[scripted_action 'unnamed' @ time_trigger(2)]", act:_tostring())
    end)
    it('should return "scripted_action \'{self.name}\' @ {self.trigger}" if some name', function ()
      local act = scripted_action(time_trigger(2), function () end, 'do_something')
      assert.are_equal("[scripted_action 'do_something' @ time_trigger(2)]", act:_tostring())
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
      local act = integration_test('character follows ground', function () end)
      assert.are_equal("[integration_test 'character follows ground']", act:_tostring())
    end)
  end)

end)
