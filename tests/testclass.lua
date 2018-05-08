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

    it('should create a new dummy_class with a value attribute', function ()
      local dummy = dummy_class(3)
      return dummy.value == 3
    end)

    it('... and an equality test on value', function ()
      return dummy_class(-5) == dummy_class(-5)
    end)

    it('... and a tostring', function ()
      return dummy_class(12):_tostring() == "dummy:12"
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
