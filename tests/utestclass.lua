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

describe('new_struct', function ()

  local dummy_struct = new_struct()

  function dummy_struct:_init(value1, value2)
    self.value1 = value1
    self.value2 = value2
  end

  function dummy_struct:_tostring()
    return "dummy: "..joinstr(", ", self.value1, self.value2)
  end

  function dummy_struct:get_sum()
    return self.value1 + self.value2
  end

  it('should create a new struct with _init()', function ()
    local dummy = dummy_struct(3, 7)
    assert.are_same({3, 7}, {dummy.value1, dummy.value2})
  end)

  it('should create a new struct with access to methods via __index', function ()
    local dummy = dummy_struct(3, 7)
    assert.are_equal(10, dummy:get_sum())
  end)

  describe('struct equality', function ()

    it('should return true for two structs equal by reference', function ()
      local dummy1 = dummy_struct(3, 7)
      assert.is_true(dummy1 == dummy1)
    end)

    it('should return true for two structs with same content', function ()
      local dummy1 = dummy_struct(3, 7)
      local dummy2 = dummy_struct(3, 7)
      assert.is_true(dummy1 == dummy2)
    end)

    it('should return false for two structs with different contents', function ()
      local dummy1 = dummy_struct(3, 7)
      local dummy2 = dummy_struct(3, -10)
      assert.is_true(dummy1 ~= dummy2)
    end)

    it('should return false for one struct and an unrelated table with same content', function ()
      local dummy1 = dummy_struct(3, 7)
      local not_the_same_struct = { value1 = 3, value2 = 7 }
      assert.is_true(dummy1 ~= not_the_same_struct)
    end)

  end)

  describe('dummy_derived struct', function ()

    local dummy_derived_struct = derived_struct(dummy_struct)

    function dummy_derived_struct:_init(value1, value2, value3)
      -- always call ._init on base struct, never :_init which would set static members
      dummy_struct._init(self, value1, value2)
      self.value3 = value3
    end

    function dummy_derived_struct:_tostring()
      return "dummy_derived: "..joinstr(", ", self.value1, self.value2, self.value3)
    end

    function dummy_derived_struct:get_sum()
      return dummy_struct.get_sum(self) + self.value3
    end

    it('should create a new struct with _init()', function ()
      local dummy_derived = dummy_derived_struct(3, 7, 9)
      assert.are_same({3, 7, 9}, {dummy_derived.value1, dummy_derived.value2, dummy_derived.value3})
    end)

    it('should create a new struct with access to methods via __index (override calling base)', function ()
      local dummy_derived = dummy_derived_struct(3, 7, 9)
      assert.are_equal(19, dummy_derived:get_sum())
    end)

    describe('struct equality', function ()

      it('should return true for two structs equal by reference', function ()
        local dummy_derived1 = dummy_derived_struct(3, 7, 9)
        assert.is_true(dummy_derived1 == dummy_derived1)
      end)

      it('should return true for two structs with same content', function ()
        local dummy_derived1 = dummy_derived_struct(3, 7, 9)
        local dummy_derived2 = dummy_derived_struct(3, 7, 9)
        assert.is_true(dummy_derived1 == dummy_derived2)
      end)

      it('should return false for two structs with different contents (on derived members only)', function ()
        local dummy_derived1 = dummy_derived_struct(3, 7, 9)
        local dummy_derived2 = dummy_derived_struct(3, 7, -99)
        assert.is_true(dummy_derived1 ~= dummy_derived2)
      end)

      it('should return false for one struct and an unrelated table with same content', function ()
        local dummy_derived1 = dummy_derived_struct(3, 7, 9)
        local not_the_same_struct = { value1 = 3, value2 = 7, value = 9 }
        assert.is_true(dummy_derived1 ~= not_the_same_struct)
      end)

    end)


  end)

end)

describe('singleton', function ()

  local my_singleton = singleton(function (self)
    self.type = "custom"
  end)

  function my_singleton:_tostring()
    return "[my_singleton "..self.type.."]"
  end

  it('should define a singleton with unique members', function ()
    assert.are_equal("custom", my_singleton.type)
  end)

  describe('changing member', function ()

    setup(function ()
      my_singleton.type = "changed"
    end)

    teardown(function ()
      my_singleton.type = "custom"
    end)

    it('init should reinit the state vars', function ()
      my_singleton:init()
      assert.are_equal("custom", my_singleton.type)
    end)

  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_singleton custom]", my_singleton:_tostring())
  end)

  it('should support string concatenation with _tostring', function ()
    assert.are_equal("this is [my_singleton custom]", "this is "..my_singleton)
  end)

end)

describe('derived_singleton', function ()

  local my_singleton = singleton(function (self)
    self.types = { "custom" }  -- the table allows us to check if __index in derived_singleton reaches it by ref to change it
  end)

  function my_singleton:get_first_type()
    return self.types[1]
  end

  function my_singleton:_tostring()
    return "[my_singleton "..self.types[1].."]"
  end

  local my_derived_singleton = derived_singleton(my_singleton, function (self)
    self.subtype = "special"
  end)

  function my_derived_singleton:_tostring()
    return "[my_derived_singleton "..self.types[1]..", "..self.subtype.."]"
  end

  it('should define a derived_singleton with base members', function ()
    assert.are_equal("custom", my_derived_singleton.types[1])
  end)

  it('should define a derived_singleton with derived members', function ()
    assert.are_equal("special", my_derived_singleton.subtype)
  end)

  describe('changing base member copy', function ()

    before_each(function ()
      my_derived_singleton.types[1] = "changed"
    end)

    after_each(function ()
      my_derived_singleton.types[1] = "custom"
    end)

    it('should create a copy of base members on the derived singleton so they are never changed on the base singleton', function ()
      assert.are_equal("custom", my_singleton.types[1])
    end)

    describe('changing base member copy', function ()

      before_each(function ()
        my_derived_singleton.subtype = "subchanged"
      end)

      after_each(function ()
        my_derived_singleton.subtype = "special"
      end)

      it('init should reinit the state vars', function ()
        assert.are_equal("changed", my_derived_singleton.types[1])
        assert.are_equal("subchanged", my_derived_singleton.subtype)
        my_derived_singleton:init()
        assert.are_equal("custom", my_derived_singleton.types[1])
        assert.are_equal("special", my_derived_singleton.subtype)
      end)

    end)

  end)

  it('should access base method: get_first_type', function ()
    assert.are_equal("custom", my_derived_singleton:get_first_type())
  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_derived_singleton custom, special]", my_derived_singleton:_tostring())
  end)

  it('should support string concatenation with _tostring', function ()
    assert.are_equal("this is [my_derived_singleton custom, special]", "this is "..my_derived_singleton)
  end)

end)
