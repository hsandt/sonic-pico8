require("engine/core/helper")

-- generic new metamethod (requires _init method)
local function new(cls, ...)
  local self = setmetatable({}, cls)  -- cls as instance metatable
  self:_init(...)
  return self
end

-- generic concat metamethod (requires _tostring method on tables)
local function concat(lhs, rhs)
  return stringify(lhs)..stringify(rhs)
end

-- metatable and memberwise equality comparison with usual equality operator
-- (shallow or deep depending on override)
-- return true iff tables have the same metatable and their members are equal
local function struct_eq(lhs, rhs)
  return getmetatable(lhs) == getmetatable(rhs) and are_same(lhs, rhs)
end

-- create and return a new class
-- every class should implement :_init(), :_tostring() and if relevant .__eq()
-- note that most .__eq() definitions are only duck-typing lhs and rhs,
-- so we can compare two instances of different classes (maybe related by inheritance)
-- with the same members. slicing will occur when comparing a base instance
-- and a derived instance with more members. add a class type member to simulate rtti
-- and make sure only objects of the same class are considered equal (but we often don't need this)
function new_class()
  local class = {}
  class.__index = class  -- 1st class as instance metatable
  class.__concat = concat

  setmetatable(class, {
    __call = new
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
    __call = new
  })

  return derived
end

-- create a new struct, which is like a class with member-wise equality
function new_struct()
  local struct = {}
  struct.__index = struct  -- 1st struct as instance metatable
  struct.__concat = concat
  struct.__eq = struct_eq

  setmetatable(struct, {
    __call = new
  })

  return struct
end

-- create and return a derived struct from a base struct, redefining metamethods for this level
function derived_struct(base_struct)
  local derived = {}
  derived.__index = derived
  derived.__concat = concat
  derived.__eq = struct_eq

  setmetatable(derived, {
    __index = base_struct,
    __call = new
  })

  return derived
end

-- create a new singleton from an init method, which can also be used as reset method in unit tests
-- the singleton is at the same time a class and its own instance
function singleton(init)
  local s = {}
  setmetatable(s, {
    __concat = concat
  })
  s.init = init
  s:init()
  return s
end

-- create a singleton from a base singleton and a derived_init method, so it can extend
-- the functionality of a singleton while providing new static fields on the spot
function derived_singleton(base_singleton, derived_init)
  local ds = {}
  -- do not set __index to base_singleton in metatable, so ds never touches the members
  -- of the base singleton (if the base singleton is concrete or has other derived singletons,
  -- this would cause them to all share and modify the same members)
  setmetatable(ds, {
    -- __index allows the derived_singleton to access base_singleton methods
    -- never define an attribute on a singleton outside init (e.g. using s.attr = value)
    -- as the "super" init in ds:init would not be able to shadow that attr with a personal attr
    -- for the derived_singleton, which would access the base_singleton's attr via __index,
    -- effectively sharing the attr with all the other singletons in that hierarchy!
    __index = base_singleton,
    __concat = concat
  })
  function ds:init()
    base_singleton.init(self)
    derived_init(self)
  end
  ds:init()
  return ds
end
