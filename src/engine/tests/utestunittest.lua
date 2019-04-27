require("engine/test/bustedhelper")
local unittest = require("engine/test/unittest")
local utest_manager, unit_test, time_trigger = unittest.utest_manager, unittest.unit_test

describe('utest_manager', function ()

  after_each(function ()
    utest_manager:init()
  end)

  describe('init', function ()

    it('should initialize utest_manager with no utests', function ()
      assert.are_same({}, utest_manager.utests)
    end)

  end)

  describe('register', function ()

    it('should register a new utest', function ()
      local utest = unit_test("test name", function () end)
      utest_manager:register(utest)
      assert.are_equal(1, #utest_manager.utests)
      assert.are_equal(utest, utest_manager.utests[1])
    end)

  end)

  describe('run_all_tests', function ()

    it('should run all the registered utests', function ()
      local spy1 = spy.new(function () end)
      local spy2 = spy.new(function () end)
      utest_manager.utests = {
        unit_test("test 1", spy1),
        unit_test("test 2", spy2)
      }
      utest_manager:run_all_tests()
      assert.spy(spy1).was_called(1)
      assert.spy(spy2).was_called(1)
    end)

  end)

end)

describe('unit_test', function ()

  describe('_init', function ()

    it('should init a unit test with a name and callback', function ()
      local callback = function () end
      local utest = unit_test("test name", callback)
      assert.are_same({"test name", callback}, {utest.name, utest.callback})
    end)

  end)

end)

describe('check', function ()

  local register_stub

  setup(function ()
    register_stub = stub(utest_manager, "register")
  end)

  teardown(function ()
    register_stub:revert()
  end)

  it('should call utest_manager:register on a new test with passed name and callback', function ()
    local callback = function () end
    check("test name", callback)
    assert.spy(register_stub).was_called(1)
    assert.spy(register_stub).was_called_with(match.ref(utest_manager), unit_test("test name", callback))
  end)

end)
