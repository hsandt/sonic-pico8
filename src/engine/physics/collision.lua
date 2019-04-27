require("engine/application/constants")
require("engine/core/math")

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
    return abs(signed_distance) * dir_vectors[escape_direction]
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

return collision
