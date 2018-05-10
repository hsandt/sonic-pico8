picotest = require("picotest")
class = require("class")

function test_class(desc,it)

  desc('dummy class', function ()

    local dummy_class = new_class()

    function dummy_class:_init(value)
      self.value = value
    end

    function dummy_class:_tostring()
      return "dummy:"..tostr(self.value)
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

    it('... concatenate with a string', function ()
      return dummy_class(11).."str" == "dummy:11str"
    end)
    it('... concatenate with a boolean', function ()
      return dummy_class(11)..true == "dummy:11true"
    end)
    it('... concatenate with a number', function ()
      return dummy_class(11)..24 == "dummy:1124"
    end)
    it('... concatenate with a number on the left', function ()
      return "27"..dummy_class(11) == "27dummy:11"
    end)
    it('... concatenate with another instance of dummy', function ()
      return dummy_class(11)..dummy_class(46) == "dummy:11dummy:46"
    end)
    it('... concatenate within a chain of objects', function ()
      return dummy_class(11)..", and "..dummy_class(46) == "dummy:11, and dummy:46"
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

    it('... and an incremented function', function ()
      return dummy_class(-5):get_incremented_value() == -4
    end)

    desc('dummy_derived class', function ()

      local dummy_derived_class = derived_class(dummy_class)

      function dummy_derived_class:_init(value, value2)
        -- always call ._init on base class, never :_init which would set static members
        dummy_class._init(self, value)
        self.value2 = value2
      end

      function dummy_derived_class:_tostring()
        return "dummy_derived:"..tostr(self.value)..","..tostr(self.value2)
      end

      function dummy_derived_class.__eq(lhs, rhs)
        return lhs.value == rhs.value and lhs.value2 == rhs.value2
      end

      it('should create a new dummy_derived_class with a value attribute', function ()
        local dummy_derived = dummy_derived_class(3, 7)
        return dummy_derived.value == 3 and dummy_derived.value2 == 7
      end)

      it('... and a tostring', function ()
        return dummy_derived_class(12, 45):_tostring() == "dummy_derived:12,45"
      end)

      it('... concatenate with a string', function ()
        return dummy_derived_class(11, 45).."str" == "dummy_derived:11,45str"
      end)
      it('... concatenate with a boolean', function ()
        return dummy_derived_class(11, 45)..true == "dummy_derived:11,45true"
      end)
      it('... concatenate with a number', function ()
        return dummy_derived_class(11, 45)..24 == "dummy_derived:11,4524"
      end)
      it('... concatenate with a number on the left', function ()
        return "27"..dummy_derived_class(11, 45) == "27dummy_derived:11,45"
      end)
      it('... concatenate with another instance of dummy_derived', function ()
        return dummy_derived_class(11, 45)..dummy_derived_class(46, 23) == "dummy_derived:11,45dummy_derived:46,23"
      end)
      it('... concatenate with an instance of dummy', function ()
        return dummy_derived_class(11, 45)..dummy_class(46) == "dummy_derived:11,45dummy:46"
      end)
      it('... concatenate within a chain of objects', function ()
        return dummy_derived_class(11, 45)..", and "..dummy_class(46) == "dummy_derived:11,45, and dummy:46"
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

    desc('immutable_class', function ()

      local immutable_dummy_class = immutable_class(dummy_class)

      it('should create a new immutable with a value attribute', function ()
        local immutable_dummy = immutable_dummy_class(3)
        return immutable_dummy ~= nil,
          immutable_dummy ~= nil and immutable_dummy.value == 3
      end)

      it('... and a tostring with _ marks', function ()
        return immutable_dummy_class(12):_tostring() == "_dummy:12_"
      end)

      it('immutable_dummy_class(11).."str" => "_dummy:11_str"', function ()
        return immutable_dummy_class(11).."str" == "_dummy:11_str"
      end)
      it('... concatenate with a boolean', function ()
        return immutable_dummy_class(11)..true == "_dummy:11_true"
      end)
      it('... concatenate with a number', function ()
        return immutable_dummy_class(11)..24 == "_dummy:11_24"
      end)
      it('... concatenate with a number on the left', function ()
        return "27"..immutable_dummy_class(11) == "27_dummy:11_"
      end)
      it('... concatenate with an instance of dummy', function ()
        return immutable_dummy_class(11)..dummy_class(46) == "_dummy:11_dummy:46"
      end)
      it('... concatenate with another instance of immutable dummy', function ()
        return immutable_dummy_class(11)..immutable_dummy_class(46, 23) == "_dummy:11__dummy:46_"
      end)
      it('... concatenate within a chain of objects', function ()
        return immutable_dummy_class(11)..", and "..dummy_class(46) == "_dummy:11_, and dummy:46"
      end)

      it('... and an equality test on value', function ()
        return immutable_dummy_class(-5) == immutable_dummy_class(-5)
      end)

      it('... same with mutable values of the same base class', function ()
        return immutable_dummy_class(-5) == dummy_class(-5)
      end)

      it('... and an inequality test on value', function ()
        return immutable_dummy_class(-5) ~= immutable_dummy_class(6)
      end)

      it('... and kept the (const) incremented function from the base class', function ()
        return immutable_dummy_class(-5):get_incremented_value() == -4
      end)

      it('cannot change immutable content', function ()
        -- this would assert
         local imm = immutable_dummy_class(-5)
         imm.value = 3
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
