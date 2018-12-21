require("engine/core/math")
require("engine/render/color")

-- sprite class
sprite_data = new_struct()

-- id_loc   sprite_id_location                      sprite location on the spritesheet
-- span     tile_vector         tile_vector(1, 1)   sprite span on the spritesheet
-- pivot    vector              (0, 0)              reference center to draw (top-left is (0 ,0))
function sprite_data:_init(id_loc, span, pivot)
  self.id_loc = id_loc
  self.span = span or tile_vector(1, 1)
  self.pivot = pivot or vector.zero()
end

--#if log
function sprite_data:_tostring()
  return "sprite_data("..(self.id_loc:_tostring())..", "..(self.span:_tostring())..", "..
    (self.pivot:_tostring())..")"
end
--#endif

-- draw this sprite at position, optionally flipped
-- position  vector
-- flip_x    bool
-- flip_y    bool
function sprite_data:render(position, flip_x, flip_y)
  set_unique_transparency(colors.pink)
  
  local draw_pos = position - self.pivot
  spr(self.id_loc:to_sprite_id(),
    draw_pos.x, draw_pos.y,
    self.span.i, self.span.j,
    flip_x, flip_y)
end
