local motion = {}

-- physics notes: collisions use fixed-point floating coordinates
--  to support fractional coordinates like classic sonic uses for motion.
-- therefore, we don't use pixel perfect collisions,
--  e.g. "touching" does not occur when two aabb's pixel representations
--  with 1px wide borders touch, but when their exact borders coincide

-- struct containing the result of a ground detection test
local ground_query_info = new_struct()
motion.ground_query_info = ground_query_info

-- signed_distance    float       signed distance to the detected ground (clamped to min-1 amd max+1)
-- slope_angle        float|nil   slope angle of the detected ground (nil if no ground)
function ground_query_info:_init(signed_distance, slope_angle)
  self.signed_distance = signed_distance
  self.slope_angle = slope_angle
end

--#if log
function ground_query_info:_tostring()
  return "ground_query_info("..joinstr(", ", self.signed_distance, tostr(self.slope_angle))..")"
end
--#endif


-- struct representing the expected result of a character ground move over a frame,
--  computed step by step. similar to a raycast hit info, specialized for ground motion
local ground_motion_result = new_struct()
motion.ground_motion_result = ground_motion_result

-- position     vector      position at the end of motion
-- slope_angle  float|nil   slope angle of the final position (nil if is_falling is true)
-- is_blocked   bool        was the character blocked during motion?
-- is_falling   bool        should the character fall after this motion?
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


-- struct representing the expected result of a character air move over a frame,
--  computed step by step. similar to a raycast hit info, specialized for air motion
local air_motion_result = new_struct()
motion.air_motion_result = air_motion_result

-- position               vector    position at the end of motion
-- is_blocked_by_wall     bool      was the character blocked by a left/right wall during motion?
-- is_blocked_by_ceiling  bool      was the character blocked by a ceiling during motion?
-- is_landing             bool      has the character landed at the end of this motion?
-- slope_angle            float|nil slope angle of the final position (nil unless is_landing is true)
function air_motion_result:_init(position, is_blocked_by_wall, is_blocked_by_ceiling, is_landing, slope_angle)
  self.position = position
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

--#if log
function air_motion_result:_tostring()
  return "air_motion_result("..joinstr(", ",
    self.position, self.is_blocked_by_wall, self.is_blocked_by_ceiling, self.is_landing, self.slope_angle)..")"
end
--#endif

return motion
