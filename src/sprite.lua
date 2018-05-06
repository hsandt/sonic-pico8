-- sprite class
sprite = {}
sprite.__index = sprite

setmetatable(sprite, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

-- i       int     sprite horizontal coordinate in the spritesheet
-- j       int     sprite vertical   coordinate in the spritesheet
-- span_i  int  1  width  of the range of sprites in the spritesheet
-- span_j  int  1  height of the range of sprites in the spritesheet
function sprite:_init(i, j, span_i, span_j)
  self.i = i
  self.j = j
  self.span_i = span_i or 1
  self.span_j = span_j or 1
end
