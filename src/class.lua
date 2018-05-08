function new_class(extra_metatable)
  class = {}
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
