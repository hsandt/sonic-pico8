-- Raw tile data as stored directly in code
-- It determines the id location of a collision mask sprite
--  and a slope angle (simply because it's simpler to define angles manually
--  than deduce it from a collision mask which may have bumps or an ambiguous angle
--  such as +1 or +2 in height depending on context).
-- Once processed in combination with either PICO-8 spritesheet
--  or a mockup process (for busted), collision mask data (height and row arrays)
--  will be injected, giving a fully-fledged tile_data.
local raw_tile_collision_data = new_struct()

-- mask_tile_id_loc  sprite_id_location    sprite location of the collision mask for this tile on the spritesheet
-- slope_angle       float                 slope angle in turn ratio (0.0 to 1.0, positive clockwise)
function raw_tile_collision_data:_init(mask_tile_id_loc, slope_angle)
  self.mask_tile_id_loc = mask_tile_id_loc
  self.slope_angle = slope_angle
end

--#if log
function raw_tile_collision_data:_tostring()
  return "raw_tile_collision_data("..joinstr(", ", self.mask_tile_id_loc:_tostring(), self.slope_angle)..")"
end
--#endif

return raw_tile_collision_data
