require("bustedhelper")
local class = require("engine/core/class")

describe('new_class', function ()

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

  it('should create a new class with _init()', function ()
    local dummy = dummy_class(3)
    assert.are_equal(3, dummy.value)
  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("dummy:12", dummy_class(12):_tostring())
  end)

  it('should support instance concatenation with a string', function ()
    assert.are_equal("dummy:11str", dummy_class(11).."str")
  end)
  it('should support instance concatenation with a boolean', function ()
    assert.are_equal("dummy:11true", dummy_class(11)..true)
  end)
  it('should support instance concatenation with a number', function ()
    assert.are_equal("dummy:1124", dummy_class(11)..24)
  end)
  it('should support instance concatenation with a number on the left', function ()
    assert.are_equal("27dummy:11", "27"..dummy_class(11))
  end)
  it('should support instance concatenation with another instance', function ()
    assert.are_equal("dummy:11dummy:46", dummy_class(11)..dummy_class(46))
  end)
  it('should support instance concatenation with a chain of objects', function ()
    assert.are_equal("dummy:11, and dummy:46", dummy_class(11)..", and "..dummy_class(46))
  end)

  it('should support metamethod: __eq for equality', function ()
    assert.are_equal(dummy_class(-5), dummy_class(-5))
  end)

  it('should support metamethod: __eq for inequality', function ()
    assert.are_not_equal(dummy_class(-5), dummy_class(-3))
  end)

  it('should support custom method: get_incremented_value', function ()
    assert.are_equal(-4, dummy_class(-5):get_incremented_value())
  end)

  describe('dummy_derived class', function ()

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
      assert.are_same({3, 7}, {dummy_derived.value, dummy_derived.value2})
    end)

    it('should support custom method: _tostring', function ()
      assert.are_equal("dummy_derived:12,45", dummy_derived_class(12, 45):_tostring())
    end)

    it('should support instance concatenation with a string', function ()
      assert.are_equal("dummy_derived:11,45str", dummy_derived_class(11, 45).."str")
    end)
    it('should support instance concatenation with a boolean', function ()
      assert.are_equal("dummy_derived:11,45true", dummy_derived_class(11, 45)..true)
    end)
    it('should support instance concatenation with a number', function ()
      assert.are_equal("dummy_derived:11,4524", dummy_derived_class(11, 45)..24)
    end)
    it('should support instance concatenation with a number on the left', function ()
      assert.are_equal("27dummy_derived:11,45", "27"..dummy_derived_class(11, 45))
    end)
    it('should support instance concatenation with another instance of dummy_derived', function ()
      assert.are_equal("dummy_derived:11,45dummy_derived:46,23", dummy_derived_class(11, 45)..dummy_derived_class(46, 23))
    end)
    it('should support instance concatenation with an instance of dummy', function ()
      assert.are_equal("dummy_derived:11,45dummy:46", dummy_derived_class(11, 45)..dummy_class(46))
    end)
    it('should support instance concatenation within a chain of objects', function ()
      assert.are_equal("dummy_derived:11,45, and dummy:46", dummy_derived_class(11, 45)..", and "..dummy_class(46))
    end)

    it('should support metamethod: __eq for equality', function ()
      assert.are_equal(dummy_derived_class(-5, 45), dummy_derived_class(-5, 45))
    end)

    it('should support metamethod: __eq for inequality', function ()
      assert.are_not_equal(dummy_derived_class(-5, 45), dummy_derived_class(-5, 43))
    end)

    it('should allow access to base class custom method: get_incremented_value', function ()
      assert.are_equal(-4, dummy_derived_class(-5, 45):get_incremented_value())
    end)

  end)

end)

describe('singleton', function ()

  local my_singleton = singleton {
    type = "custom"
  }

  function my_singleton:_tostring()
    return "[my_singleton "..self.type.."]"
  end

  it('should define a singleton with unique members', function ()
    assert.are_equal("custom", my_singleton.type)
  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_singleton custom]", my_singleton:_tostring())
  end)

  it('should support string concatenation with _tostring', function ()
    assert.are_equal("this is [my_singleton custom]", "this is "..my_singleton)
  end)

end)
