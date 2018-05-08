picotest = require("picotest")
helper = require("helper")

function test_helper(desc,it)

  desc('clear_table', function ()
    it('should clear a sequence', function ()
      local t = {1, 5, -5}
      clear_table(t)
      return #t == 0
    end)
    it('should clear a table', function ()
      local t = {1, 5, a = "b", b = 50.1}
      clear_table(t)
      for k, v in pairs(t) do
        return false
      end
      return true
    end)
  end)

  desc('unpack', function ()
    it('should unpack a sequence fully by default', function ()
      local function foo(a, b, c)
        return a == 1 and b == "foo" and c == 20.2
      end
      return foo(unpack({1, "foo", 20.2}))
    end)
    it('should unpack a sequence from start if from is not passed', function ()
      local function foo(a, b, c, d)
        return a == 1 and b == "foo" and c == 20.2 and d ~= 50
      end
      return foo(unpack({1, "foo", 20.2, 50}, nil, 3))
    end)
    it('should unpack a sequence to the end if to is not passed', function ()
      local function foo(a, b, c)
        return a == 1 and b == "foo" and c == 20.2
      end
      return foo(unpack({45, 1, "foo", 20.2}, 2))
    end)
    it('should unpack a sequence from from to to', function ()
      local function foo(a, b, c, d)
        return a == 1 and b == "foo" and c == 20.2 and d ~= 50
      end
      return foo(unpack({45, 1, "foo", 20.2, 50}, 2, 4))
    end)
  end)

end

add(picotest.test_suite, test_helper)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('helper', test_helper)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
