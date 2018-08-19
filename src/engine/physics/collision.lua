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
function aabb:collides(other, prioritized_escape_direction)
  local self_left = self.center.x - self.extents.x
  local self_right = self.center.x + self.extents.x
  local self_top = self.center.y - self.extents.y
  local self_bottom = self.center.y + self.extents.y
  local other_left = other.center.x - other.extents.x
  local other_right = other.center.x + other.extents.x
  local other_top = other.center.y - other.extents.y
  local other_bottom = other.center.y + other.extents.y

  -- check the signed distance of each edge against the other box' vertices
  -- in polygon theory we are supposed to check all the other vertices and get the minimum signed distance, but for aabb
  -- it's much simpler since we know that self_left - other_right <= self_left - other_left, so we directly compute the lowest value
  local min_signed_distance_x1 = self_left - other_right
  local min_signed_distance_x2 = other_left - self_right
  local min_signed_distance_y1 = self_top - other_bottom
  local min_signed_distance_y2 = other_top - self_bottom

  -- retrieve the max of all these signed distances and the corresponding escape vector
  -- in polygon theory we are supposed to redo the same ops by swapping the box' roles (edge of box1, vertex of box2 then reversely)
  -- but for aabb, it's simpler because everything is aligned so the distances edge-vertex are really just edge-edge distances
  local escape_vector
  local max_signed_distance = - math.huge
  if min_signed_distance_x1 > max_signed_distance then
    max_signed_distance = min_signed_distance_x1
    escape_vector = vector(- max_signed_distance, 0)
  end
  if min_signed_distance_x2 > max_signed_distance or min_signed_distance_x2 == max_signed_distance and prioritized_escape_direction == directions.left then
    max_signed_distance = min_signed_distance_x2
    escape_vector = vector(max_signed_distance, 0)
  end
  if min_signed_distance_y1 > max_signed_distance or min_signed_distance_y1 == max_signed_distance and prioritized_escape_direction == directions.down then
    max_signed_distance = min_signed_distance_y1
    escape_vector = vector(0, - max_signed_distance)
  end
  if min_signed_distance_y2 > max_signed_distance or min_signed_distance_y2 == max_signed_distance and prioritized_escape_direction == directions.up then
    max_signed_distance = min_signed_distance_y2
    escape_vector = vector(0, max_signed_distance)
  end

  if max_signed_distance >= 0 then
    return nil
  end

  return escape_vector
end

-- return true iff aabb and other's boundaries are intersection but their interiors are not
-- if some aabb extents has a 0 component, it is treated with a very thin or small box, not a no-touch
function aabb:touches(other)
  local self_left = self.center.x - self.extents.x
  local self_right = self.center.x + self.extents.x
  local self_top = self.center.y - self.extents.y
  local self_bottom = self.center.y + self.extents.y
  local other_left = other.center.x - other.extents.x
  local other_right = other.center.x + other.extents.x
  local other_top = other.center.y - other.extents.y
  local other_bottom = other.center.y + other.extents.y

  local min_signed_distance_x1 = self_left - other_right
  local min_signed_distance_x2 = other_left - self_right
  local min_signed_distance_y1 = self_top - other_bottom
  local min_signed_distance_y2 = other_top - self_bottom

  if math.max(min_signed_distance_x1, min_signed_distance_x2, min_signed_distance_y1, min_signed_distance_y2) == 0 then
    return true
  end

  return false
end

-- return escape_vector if aabb and other's boundaries or interiors are intersecting, prioritizing optional escape direction
-- else return nil
-- if only the boundaries are touching, escape_vector is zero. otherwise it's the same as returned by the 'collides' method
function aabb:intersects(other, prioritized_escape_direction)
  if self:touches(other) then
    return vector:zero()
  end

  return self:collides(other, prioritized_escape_direction)
end

return collision
