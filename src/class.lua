require("helper")

-- generic call metamethod (requires _init method)
local function call(cls, ...)
  local self = setmetatable({}, cls)
  self:_init(...)
  return self
end

-- generic concat metamethod (requires _tostring method on tables)
local function concat(lhs, rhs)
  return tostring(lhs)..tostring(rhs)
end

-- create and return a new class
function new_class()
  local class = {}
  class.__index = class
  class.__concat = concat

  setmetatable(class, {
    __call = call
  })

  return class
end

-- create and return a derived class from a base class
function derived_class(base_class)
  local derived_class = {}
  derived_class.__index = derived_class
  derived_class.__concat = concat

  setmetatable(derived_class, {
    __index = base_class,
    __call = call
  })

  return derived_class
end
