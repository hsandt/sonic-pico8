require("engine/application/constants")
require("engine/core/math")

-- physics notes: collisions use fixed-point floating coordinates
--  to support fractional coordinates like classic sonic uses for motion.
-- therefore, we don't use pixel perfect collisions,
--  e.g. "touching" does not occur when two aabb's pixel representations
--  with 1px wide borders touch, but when their exact borders coincide

local collision = {}

-- axis-aligned bounding box struct
local aabb = new_struct()
collision.aabb = aabb

-- center   vector  center of the box
-- extents  vector  half-size of the box. components must be positive or zero
function aabb:_init(center, extents)
  self.center = center
  self.extents = extents
end

--#if log
function aabb:_tostring()
  return "aabb("..self.center..", "..self.extents..")"
end
--#endif

-- mirror the aabb horizontally in-place
function aabb:mirror_x()
  self.center:mirror_x()
end

-- mirror the aabb vertically in-place
function aabb:mirror_y()
  self.center:mirror_y()
end

-- return copy of aabb rotated by 90 degrees clockwise
-- extents coordinates are swapped to match the new orientation
function aabb:rotated_90_cw()
  local swapped_extents = vector(self.extents.y, self.extents.x)
  return aabb(self.center:rotated_90_cw(), swapped_extents)
end

-- rotate by 90 degrees clockwise in-place
-- extents coordinates are swapped to match the new orientation
function aabb:rotate_90_cw_inplace()
  local rotated_aabb = self:rotated_90_cw()
  self.center = rotated_aabb.center
  self.extents = rotated_aabb.extents
end

-- return copy of aabb rotated by 90 degrees counter-clockwise
-- extents coordinates are swapped to match the new orientation
function aabb:rotated_90_ccw()
  local swapped_extents = vector(self.extents.y, self.extents.x)
  return aabb(self.center:rotated_90_ccw(), swapped_extents)
end

-- rotate by 90 degrees counter-clockwise in-place
-- extents coordinates are swapped to match the new orientation
function aabb:rotate_90_ccw_inplace()
  local rotated_aabb = self:rotated_90_ccw()
  self.center = rotated_aabb.center
  self.extents = rotated_aabb.extents
end

-- helper function for collides, touches and intersects, that return a couple (signed_distance, escape_vector)
-- where signed_distance is the signed distance between this aabb and another one (negative when boxes are intersecting),
-- for a given prioritized escape direction, the escape direction won't be used by calling methods if signed_distance > 0,
-- but it would still have the meaning of the direction in which bb1 should go to go even further away from bb2
function aabb:_compute_signed_distance_and_escape_direction(other, prioritized_escape_direction)
  local self_left = self.center.x - self.extents.x
  local self_right = self.center.x + self.extents.x
  local self_top = self.center.y - self.extents.y
  local self_bottom = self.center.y + self.extents.y
  local other_left = other.center.x - other.extents.x
  local other_right = other.center.x + other.extents.x
  local other_top = other.center.y - other.extents.y
  local other_bottom = other.center.y + other.extents.y

  -- in convex polygon theory, we estimate the distance between polygons with a "phi-function" which is evaluated as:
  -- (maximum when swapping polygons A and B of
  --  (maximum when iterating over A's edges of
  --    (minimum when iterating over B's vertices of
  --      signed distance of B's vertex from A's edge where A's edge positive side is oriented toward the outside of A)))
  -- for aabb, it's much simpler since all sides are aligned and we know what edge coordinate differences are lower than others (e.g. other_left - self_right < other_left - self_left)
  -- besides, we don't have to swap the box' roles since the distances edge-vertex are really just edge-edge distances, which are symmetrical
  -- so we use a much simplified operation. however, unlike phi-function we only compute the escape vector while iterating

  -- table of lowest signed distances between edge of box 1 and edge of box 2, indexed by potential escape direction (if that distance is negative)
  local min_signed_edge_to_edge_distances = {
    [0] = other_left - self_right,  -- 0: left
    other_top - self_bottom,        -- 1: up
    self_left - other_right,        -- 2: right
    self_top - other_bottom         -- 3: down
  }

  -- find max of the signed distances, while defining the associated escape vector
  local max_signed_distance = - math.huge
  local best_escape_direction = nil
  for escape_direction, signed_distance in pairs(min_signed_edge_to_edge_distances) do
    -- check prioritized_escape_direction in case of equality (in which case only the 2nd assignment in the block is useful)
    if signed_distance > max_signed_distance or signed_distance == max_signed_distance and prioritized_escape_direction == escape_direction then
      max_signed_distance = signed_distance
      -- only set escape_vector if the boxes projected on this axis are intersecting (they still may not intersect if they are separate in the other axis)
      -- note that if we replace abs(signed_distance) with - signed_distance, we get a generic formula for a motion vector
      -- that will ensure both boxes are just touching (escape when signed_distance < 0, come to contact if signed_distance > 0)
      best_escape_direction = escape_direction
    end
  end

  return max_signed_distance, best_escape_direction
end

-- return escape_vector if aabb and other's interiors are intersecting
--  where escape_vector is the minimal motion in magnitude that this aabb can do
--  to escape collision (leaving it in a touching state with other).
--  if multiple escape vectors with the same magnitude exist, an arbitrary one is chosen
-- else return nil
-- if optional prioritized_escape_direction is set, in case of draw between the smallest escape vectors, the prioritized_escape_direction is chosen
-- note that classic sonic uses an ultimate direction where sonic would be pushed in the opposite direction of his last motion
--  to escape a collider, even if it meant moving of a much longer distance that in other directions (this is a known exploit for speedruns)
--  but we prefer picking the smallest escape vector whatever
-- if some aabb extents has a 0 component, it is treated with a very thin or small box, not a no-collision
function aabb:compute_escape_vector(other, prioritized_escape_direction)
  signed_distance, escape_direction = self:_compute_signed_distance_and_escape_direction(other, prioritized_escape_direction)
  if signed_distance < 0 then
    return abs(signed_distance) * direction_vectors[escape_direction]
  else
    return nil
  end
end

function aabb:collides(other)
  signed_distance, _ = self:_compute_signed_distance_and_escape_direction(other, nil)
  return signed_distance < 0
end

-- return true iff aabb and other's boundaries are intersection but their interiors are not
-- if some aabb extents has a 0 component, it is treated with a very thin or small box, not a no-touch
function aabb:touches(other)
  signed_distance, _ = self:_compute_signed_distance_and_escape_direction(other, nil)
  return signed_distance == 0
end

-- return true iff aabb and other's boundaries or interiors are intersecting
function aabb:intersects(other)
  signed_distance, _ = self:_compute_signed_distance_and_escape_direction(other, nil)
  return signed_distance <= 0
end

-- struct representing the expected result of a character move over a frame,
--  computed step by step
local ground_motion_result = new_struct()
collision.ground_motion_result = ground_motion_result

-- position     vector   position at the end of motion
-- slope_angle  float    slope angle of the final position
-- is_blocked   bool     was the character blocked during motion?
-- is_falling   bool     should the character fall after this motion?
function ground_motion_result:_init(position, slope_angle, is_blocked, is_falling)
  self.position = position
  self.slope_angle = slope_angle
  self.is_blocked = is_blocked
  self.is_falling = is_falling
end

--#if log
function ground_motion_result:_tostring()
  return "ground_motion_result("..joinstr(", ", self.position, self.slope_angle, self.is_blocked, self.is_falling)..")"
end
--#endif


local tile_data = new_struct()
collision.tile_data = tile_data

-- id_loc         sprite_id_location    sprite location on the spritesheet
-- slope_angle    float                 slope angle in turn ratio (0.0 to 1.0, positive clockwise)
function tile_data:_init(id_loc, slope_angle)
  self.id_loc = id_loc
  self.slope_angle = slope_angle
end

--#if log
function tile_data:_tostring()
  return "tile_data("..joinstr(", ", self.id_loc:_tostring(), self.slope_angle)..")"
end
--#endif


local height_array = new_struct()
collision.height_array = height_array

-- tile_data_value    tile_data              tile data to generate the height array from
-- _array             [int]                  sequence of heights of a tile collision mask column per index,
--                                            counting index from the left, height from the bottom
--                                            it is filled based on tile_mask_id_location
-- slope_angle        float                  slope angle in turn ratio (0.0 to 1.0)
function height_array:_init(tile_data_value)
  self._array = {}
  self._fill_array(self._array, tile_data_value.id_loc)
  self.slope_angle = tile_data_value.slope_angle
end

--#if log
function height_array:_tostring()
  return "height_array("..joinstr(", ", "{"..joinstr_table(", ", self._array).."}", self.slope_angle)..")"
end
--#endif

-- return the height for a column index starting at 0, from left to right
function height_array:get_height(column_index0)
  return self._array[column_index0 + 1]  -- adapt 0-index to 1-index
end


-- fill the passed array with height data based on the sprite mask
--  located at tile_mask_id_location: sprite_id_location
-- pass an empty array so it is only filled with the computed values
-- the tile mask must represent the collision mask of a tile, with columns
--  of non-transparent (black) pixels filled from the bottom,
--  or at least the upper edge of said mask (we don't check what is below
--  the edge once we found the first non-transparent pixel from top to bottom)
function height_array._fill_array(array, tile_mask_id_location)
  local tile_mask_topleft_position = tile_mask_id_location:to_topleft_position()
  -- iterate over columns from left to right, searching for the highest filled pixel
  for dx = 0, tile_size - 1 do
    -- iterate from the top of the column and stop at the first filled pixel (we assume
    -- lower pixels are also filled for readability of the tile mask, but not enforced)
    local mask_height = 0
    for dy = 0, tile_size - 1 do
      local tile_mask_color = sget(tile_mask_topleft_position.x + dx, tile_mask_topleft_position.y + dy)
      -- we use black (0) as transparent mask color
      if tile_mask_color ~= 0 then
        mask_height = tile_size - dy
        break
      end
    end
    add(array, mask_height)
  end
end

return collision
