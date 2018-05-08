picotest = require("picotest")
class = require("class")

function test_class(desc,it)

  desc('dummy class', function ()

    local dummy_class = new_class()

    function dummy_class:_init(value)
      self.value = value
    end

    function dummy_class:_tostring(value)
      return "dummy:"..self.value
    end

    function dummy_class.__eq(lhs, rhs)
      return lhs.value == rhs.value
    end

    function dummy_class:get_incremented_value()
      return self.value + 1
    end

    it('should create a new dummy_class with a value attribute', function ()
      local dummy = dummy_class(3)
      return dummy.value == 3
    end)

    it('... and a tostring', function ()
      return dummy_class(12):_tostring() == "dummy:12"
    end)

    it('... and an equality test on value', function ()
      return dummy_class(-5) == dummy_class(-5)
    end)

    it('... and an inequality test on value', function ()
      return dummy_class(-5) ~= dummy_class(-3)
    end)

    it('... and an incremented function', function ()
      return dummy_class(-5):get_incremented_value() == -4
    end)

    desc('dummy derived class', function ()

      local dummy_derived_class = derived_class(dummy_class)

      function dummy_derived_class:_init(value, value2)
        dummy_class:_init(value)
        self.value2 = value2
      end

      function dummy_derived_class:_tostring(value)
        return "dummy derived:"..self.value..","..self.value2
      end

      function dummy_derived_class.__eq(lhs, rhs)
        return lhs.value == rhs.value and lhs.value2 == rhs.value2
      end

      it('should create a new dummy_derived_class with a value attribute', function ()
        local dummy_derived = dummy_derived_class(3, 7)
        return dummy_derived.value == 3 and dummy_derived.value2 == 7
      end)

      it('... and a tostring', function ()
        return dummy_derived_class(12, 45):_tostring() == "dummy derived:12,45"
      end)

      it('... and an equality test on value', function ()
        return dummy_derived_class(-5, 45) == dummy_derived_class(-5, 45)
      end)

      it('... and an inequality test on value', function ()
        return dummy_derived_class(-5, 45) ~= dummy_derived_class(-5, 43)
      end)

      it('... and kept the incremented function from the base class', function ()
        return dummy_derived_class(-5, 45):get_incremented_value() == -4
      end)

    end)

  end)

end

add(picotest.test_suite, test_class)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('class', test_class)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
