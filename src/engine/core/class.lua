require("engine/core/helper")

-- generic call metamethod (requires _init method)
local function call(cls, ...)
  local self = setmetatable({}, cls)  -- cls as instance metatable
  self:_init(...)
  return self
end

-- generic concat metamethod (requires _tostring method on tables)
local function concat(lhs, rhs)
  return tostring(lhs)..tostring(rhs)
end

-- create and return a new class
-- every class should implement :_init(), :_tostring() and .__eq()
-- note that .__eq() is only duck-typing lhs and rhs, so we can compare
-- two instances of different classes (maybe related by inheritance)
-- with the same members. slicing will occur when comparing a base instance
-- and a derived instance with more members
function new_class()
  local class = {}
  class.__index = class  -- 1st class as instance metatable
  class.__concat = concat

  setmetatable(class, {
    __call = call
  })

  return class
end

-- create and return a derived class from a base class
function derived_class(base_class)
  local derived = {}
  derived.__index = derived
  derived.__concat = concat

  setmetatable(derived, {
    __index = base_class,
    __call = call
  })

  return derived
end

-- create and return an immutable class from a base class
-- immutable classes don't add new features to the base class besides immutability
-- the base class must implement :_copy() if you intend to assign the instance value
-- to mutable variables of the base class.
function immutable_class(base_class)
  local immutable = {}
  immutable.__index = base_class  -- don't add new members to your immutable
  immutable.__concat = concat
  immutable.__eq = base_class.__eq

  setmetatable(immutable, {
    __call = function (cls, ...)
      self = call(cls, ...)
      function self:_tostring()
        return "_"..base_class._tostring(self).."_"  -- just to differenciate immutables from the rest
      end
      return self
    end
  })

  return immutable
end
