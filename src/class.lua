function new_class()
  local class = {}
  class.__index = class

  setmetatable(class, {
    __call = function (cls, ...)
      local self = setmetatable({}, cls)
      self:_init(...)
      return self
    end,
  })

  return class
end

function derived_class(base_class)
  local derived_class = {}
  derived_class.__index = derived_class

  setmetatable(derived_class, {
    __index = base_class,
    __call = function (cls, ...)
      local self = setmetatable({}, cls)
      self:_init(...)
      return self
    end,
  })

  return derived_class
end
