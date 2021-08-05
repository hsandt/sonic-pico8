local motion = {}

-- physics notes: collisions use fixed-point floating coordinates
--  to support fractional coordinates like classic sonic uses for motion.
-- therefore, we don't use pixel perfect collisions,
--  e.g. "touching" does not occur when two aabb's pixel representations
--  with 1px wide borders touch, but when their exact borders coincide

-- struct containing the result of a ground detection test (a kind of raycast adapted to our height array system)
local ground_query_info = new_struct()
motion.ground_query_info = ground_query_info

-- tile_location      location|nil location of detected ground tile (nil if no ground)
-- signed_distance    float        signed distance to the detected ground (clamped to min-1 and max+1)
-- slope_angle        float|nil    slope angle of the detected ground (nil if no ground)
function ground_query_info:init(tile_location, signed_distance, slope_angle)
  self.tile_location = tile_location
  self.signed_distance = signed_distance
  self.slope_angle = slope_angle
end

--#if tostring
function ground_query_info:_tostring()
  return "ground_query_info("..joinstr(", ", self.tile_location, self.signed_distance, tostr(self.slope_angle))..")"
end
--#endif


-- struct representing the expected result of a character ground move over a frame,
--  computed step by step. similar to a raycast hit info, specialized for ground motion
local ground_motion_result = new_struct()
motion.ground_motion_result = ground_motion_result

-- tile_location location|nil location of ground tile at the end of motion (nil if no ground i.e. is_falling)
-- position      vector       position at the end of motion
-- slope_angle   float|nil    slope angle of the final position (nil if is_falling is true)
-- is_blocked    bool         was the character blocked during motion?
-- is_falling    bool         should the character fall after this motion?
function ground_motion_result:init(tile_location, position, slope_angle, is_blocked, is_falling)
  -- we don't assert symmetrically to air_motion_result:
  --  it's possible to have no ground tile location and not is_falling
  --  when _check_escape_from_ground found character too deep inside ground,
  --  so it can have the grounded animation with slope 0 but no specific tile to walk on
  assert((tile_location == nil) == is_falling, "tile location is "..stringify(tile_location).." but is_falling is "..tostr(is_falling))
  assert(type(slope_angle) == "number" or slope_angle == nil)
  self.tile_location = tile_location
  self.position = position
  self.slope_angle = slope_angle
  self.is_blocked = is_blocked
  self.is_falling = is_falling
end

--#if tostring
function ground_motion_result:_tostring()
  return "ground_motion_result("..joinstr(", ", self.tile_location, self.position, self.slope_angle, self.is_blocked, self.is_falling)..")"
end
--#endif


-- struct representing the expected result of a character air move over a frame,
--  computed step by step. similar to a raycast hit info, specialized for air motion
local air_motion_result = new_struct()
motion.air_motion_result = air_motion_result

-- tile_location          location|nil location of ground tile at the end of motion (nil if no ground i.e. not is_landing)
-- is_blocked_by_wall     bool         was the character blocked by a left/right wall during motion?
-- is_blocked_by_ceiling  bool         was the character blocked by a ceiling during motion?
-- is_landing             bool         has the character landed at the end of this motion?
-- slope_angle            float|nil    slope angle of the final position (nil unless is_landing is true)

-- note: we removed member position since air_motion_result is now only returned by check_air_collisions
--  which is done in-place on character current position
function air_motion_result:init(tile_location, is_blocked_by_wall, is_blocked_by_ceiling, is_landing, slope_angle)
  assert((tile_location ~= nil) == is_landing, "tile location is "..stringify(tile_location).." but is_landing is "..tostr(is_landing))
  assert(type(is_blocked_by_wall) == "boolean")
  self.tile_location = tile_location
  self.is_blocked_by_wall = is_blocked_by_wall
  self.is_blocked_by_ceiling = is_blocked_by_ceiling
  self.is_landing = is_landing
  self.slope_angle = slope_angle
end

-- return true iff motion result indicates a blocker in the given direction
function air_motion_result:is_blocked_along(direction)
  if direction == directions.left or direction == directions.right then
    return self.is_blocked_by_wall
  elseif direction == directions.up then
    return self.is_blocked_by_ceiling
  else  -- direction == directions.down
    return self.is_landing
  end
end

--#if tostring
function air_motion_result:_tostring()
  return "air_motion_result("..joinstr(", ",
    self.tile_location, self.is_blocked_by_wall, self.is_blocked_by_ceiling, self.is_landing, self.slope_angle)..")"
end
--#endif

return motion
