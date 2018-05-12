picotest = require("picotest")
helper = require("helper")
math = require("math")  -- just to test tostring

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

  desc('tostring', function ()
    it('nil => "nil"', function ()
      return tostring(nil) == "[nil]"
    end)
    it('"string" => "string"', function ()
      return tostring("string") == "string"
    end)
    it('true => "true"', function ()
      return tostring(true) == "true"
    end)
    it('false => "false"', function ()
      return tostring(false) == "false"
    end)
    it('56 => "56"', function ()
      return tostring("56") == "56"
    end)
    it('56.2 => "56.2"', function ()
      return tostring("56.2") == "56.2"
    end)
    it('vector(2 3) => "vector(2 3)" (_tostring implemented)', function ()
      return tostring(vector(2, 3)) == "vector(2, 3)"
    end)
    it('{} => "[table]" (_tostring not implemented)', function ()
      return tostring({}) == "[table]"
    end)

  end)

  desc('joinstr_table', function ()
    it('joinstr_table("_" {nil 5 "at" nil}) => "[nil]_5_at"', function ()
      return joinstr_table("_", {nil, 5, "at", nil}) == "[nil]_5_at"
    end)
    it('joinstr_table("comma " nil 5 "at" {}) => "[nil]comma 5comma atcomma [table]"', function ()
      return joinstr_table(", ", {nil, 5, "at", {}}) == "[nil], 5, at, [table]"
    end)
  end)

  desc('joinstr', function ()
    it('joinstr("" nil 5 "at" nil) => "[nil]5at"', function ()
      return joinstr("", nil, 5, "at", nil) == "[nil]5at"
    end)
    it('joinstr("comma " nil 5 "at" {}) => "[nil]comma 5comma atcomma [table]"', function ()
      return joinstr(", ", nil, 5, "at", {}) == "[nil], 5, at, [table]"
    end)
  end)

  desc('yield_delay (wrapped in set_var_after_delay_async)', function ()

    local test_var = 0

    local function set_var_after_delay_async(delay)
      yield_delay(delay)
      test_var = 1
    end

    local coroutine = cocreate(set_var_after_delay_async)

    it('should start suspended', function ()
      return costatus(coroutine) == "suspended",
        test_var == 0
    end)
    it('should not stop after 59/60 frames', function ()
      coresume(coroutine, 1.0)  -- pass delay of 60 frames in 1st call
      for t=2,59 do
        coresume(coroutine)  -- further calls don't need arg, it's only used as yield() return value
      end
      return costatus(coroutine) == "suspended",
        test_var == 0
    end)
    it('should stop after the 60th frame', function ()
      coresume(coroutine)  -- one more
      return costatus(coroutine) == "dead"
    end)
    it('should continue execution of body after 1s', function ()
      return test_var == 1
    end)

    test_var = 0  -- reset

    local coroutine = cocreate(set_var_after_delay_async)

    it('should start suspended', function ()
      return costatus(coroutine) == "suspended",
        test_var == 0
    end)
    it('should not stop after 60/60.6 frames', function ()
      coresume(coroutine, 1.01)  -- pass delay of 60.6 frames in 1st call
      for t=2,60 do
        coresume(coroutine)
      end
      return costatus(coroutine) == "suspended",
        test_var == 0
    end)
    it('should stop after the 61th frame (ceil of 60.6)', function ()
      coresume(coroutine)  -- one more
      return costatus(coroutine) == "dead"
    end)
    it('... and continue execution of body', function ()
      return test_var == 1
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
