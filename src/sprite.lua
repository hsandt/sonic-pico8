require("math")

-- sprite class
sprite_data = {}
sprite_data.__index = sprite_data

setmetatable(sprite_data, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

-- sprite_id_loc   sprite_id_location                     sprite location on the spritesheet
-- sprite_span     tile_vector         tile_vector(1, 1)  sprite span on the spritesheet
function sprite_data:_init(sprite_id_loc, sprite_span)
  self.sprite_id_loc = sprite_id_loc
  self.sprite_span = sprite_span or tile_vector(1, 1)
end

-- draw this sprite at position, optionally flipped
function sprite_data:render(position, flip_x, flip_y)
  spr(sprite_id_loc:to_sprite_id(), position.x, position.y, self.sprite_span.i, self.sprite_span.j, flip_x, flip_y)
end
