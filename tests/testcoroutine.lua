local picotest = require("picotest")
require("coroutine")

function test_coroutine(desc,it)

  function test_fun_async_with_args(var1, var2)
  end

  desc('coroutine_curry._init', function ()
    it('should initialize a coroutine curry with some arguments', function ()
      local t = {}
      local curry = coroutine_curry(test_fun_async_with_args, 5, t)
      return #curry.args == 2,
        #curry.args >= 1 and curry.args[1] == 5,
        #curry.args >= 2 and curry.args[2] == t
    end)
  end)

  desc('coroutine_curry._tostring', function ()
    it('should return "[coroutine_curry] (arg1 arg2 ...)"', function ()
      return coroutine_curry(test_fun_async_with_args, 5, {}):_tostring() == "[coroutine_curry] (5, [table])"
    end)
  end)

end

add(picotest.test_suite, test_coroutine)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('coroutine', test_coroutine)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
