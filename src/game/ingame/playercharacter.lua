require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
require("engine/core/math")
require("engine/render/sprite")
local collision = require("engine/physics/collision")
local collision_data = require("game/data/collision_data")
local playercharacter_data = require("game/data/playercharacter_data")

-- enum for character control
control_modes = {
  human = 1,      -- player controls character
  ai = 2,         -- ai controls character
  puppet = 3      -- itest script controls character
}

-- enum for character motion mode
motion_modes = {
  platformer = 1, -- normal in-game
  debug = 2       -- debug "fly" mode
}

-- enum for character motion state in platformer mode
motion_states = {
  grounded = 1,       -- character is on the ground
  airborne = 2        -- character is in the air
}

local player_character = new_class()


-- parameters
-- spr_data             sprite_data   sprite data
-- debug_move_max_speed   float         move max speed in debug mode
-- debug_move_accel       float         move acceleration in debug mode
-- debug_move_decel       float         move deceleration in debug mode
-- state vars
-- control_mode           control_modes control mode: human (default) or ai
-- motion_mode            motion_modes  motion mode: platformer (under gravity) or debug (fly around)
-- motion_state           motion_states motion state (platformer mode only)
-- position               vector        current position (character center "between" pixels)
-- ground_speed_frame     float         current speed along the ground (~px/frame)
-- velocity_frame         vector        current velocity in platformer mode (px/frame)
-- debug_velocity         vector        current velocity in debug mode (m/s)
-- move_intention         vector        current move intention (normalized)
-- jump_intention         bool          current intention to start jump (consumed on jump)
-- hold_jump_intention    bool          current intention to hold jump (always true when jump_intention is true)
-- should_jump            bool          should the character jump when next frame is entered? used to delay variable jump/hop by 1 frame
-- has_interrupted_jump   bool          has the character already interrupted his jump once?
function player_character:_init()
  self.spr_data = playercharacter_data.character_sprite_data
  self.debug_move_max_speed = playercharacter_data.debug_move_max_speed
  self.debug_move_accel = playercharacter_data.debug_move_accel
  self.debug_move_decel = playercharacter_data.debug_move_decel

  self.control_mode = control_modes.human
  self.motion_mode = motion_modes.platformer
  self.motion_state = motion_states.grounded

  self.position = vector.zero()
  self.ground_speed_frame = 0.
  self.velocity_frame = vector.zero()
  self.debug_velocity = vector.zero()

  self.move_intention = vector.zero()
  self.jump_intention = false
  self.hold_jump_intention = false
  self.should_jump = false
  self.has_interrupted_jump = false
end

--#if log
function player_character:_tostring()
 return "[player_character at "..self.position.."]"
end
--#endif

-- spawn character at given position, and escape from ground / enter airborne state if needed
function player_character:spawn_at(position)
  self.position = position
  self:_check_escape_from_ground_and_update_motion_state()
end

-- update player position
function player_character:update()
  if self.motion_mode == motion_modes.platformer then
    self:_update_platformer_motion()
  else  -- self.motion_mode == motion_modes.debug
    self:_update_debug()
  end
end

-- -- return signed distance to closest ground, either negative when (in abs, penetration height)
-- --  or positive (actual distance to ground), always clamped to tile_size+1
-- -- if both sensors have different signed distances,
-- --  the lowest signed distance is returned (to escape completely or to have just 1 sensor snapping to the ground)
-- function player_character:_compute_signed_distance_to_closest_ground()

--   -- initialize with negative value to return if the character is not intersecting ground
--   local min_signed_distance = 1 / 0  -- max (32768, but never enter it manually as it would be negative)

--   -- check both ground sensors for ground. if any finds ground, return true
--   for i in all({horizontal_directions.left, horizontal_directions.right}) do

--     -- find the tile where this ground sensor is located
--     local sensor_position = self:_get_ground_sensor_position(i)
--     local sensor_location = sensor_position:to_location()

--     -- get column on the collision mask that the ground sensor should check (ground sensor extent x
--     --  should be in 0.5 and the 0.5->1 rounding should apply automatically due to flooring)
--     -- note that this is slightly suboptimal as we won't use column_index0 at all if _compute_column_height_at returns early

--     local sensor_location_topleft = sensor_location:to_topleft_position()
--     local sensor_relative_x = sensor_position.x - sensor_location_topleft.x
--     local column_index0 = flr(sensor_relative_x)  -- from 0 to tile_size - 1
--     local ground_column_height = self:_compute_column_height_at(sensor_location, column_index0)

--     -- compute relative height of sensor from tile bottom (y axis is downward)
--     local sensor_location_bottom = sensor_location_topleft.y + tile_size
--     local sensor_height = sensor_location_bottom - sensor_position.y
--     assert(sensor_height > 0, "player_character:_compute_signed_distance_to_closest_ground: sensor_height is not positive, yet it was computed using sensor_position:to_location() which should always select a tile where the sensor is strictly above the bottom")

--     -- check that ground sensor #i is on top of or below the mask column
--     local signed_distance = sensor_height - ground_column_height

--     -- note: if character is inside a tile but his feet are just at the bottom of this tile
--     --  and the signed distance will be computed by checking any tile below (if no tile, will be tile_size+1)
--     -- so always add a solid ground below a step up or a slope to avoid the character falling there
--     -- if you want to check that case as well, check if sensor_height == tile_size, and in this case
--     --  check the tiles above first, e.g. using _compute_stacked_column_height_above

--     if ground_column_height == tile_size then
--       -- column is full (reaches the top of the tile), we must check if there are any tiles
--       --  stacked on top of this one, in which case the penetration height will be incremented by everything above (up to a limit of tile_size, so we clamp
--       --  the added value by tile_size minus what we've already got)
--       assert(signed_distance <= 0, "player_character:_compute_signed_distance_to_closest_ground: column is full yet sensor is considered above it")
--       signed_distance = signed_distance - self:_compute_stacked_column_height_above(sensor_location, column_index0, tile_size + signed_distance)
--     elseif ground_column_height == 0 then
--       -- column is empty, check for more space below, up to a tile size
--       assert(signed_distance >= 0, "player_character:_compute_signed_distance_to_closest_ground: column is empty yet sensor is considered below it")
--       signed_distance = signed_distance + self:_compute_stacked_empty_column_height_below(sensor_location, column_index0, tile_size - signed_distance)
--     end

--     -- store the biggest penetration height among sensors
--     if signed_distance < min_signed_distance then
--       min_signed_distance = signed_distance
--     end

--   end

--   return min_signed_distance

-- end

-- return signed distance to closest ground when character center is at center_position,
--  either negative when (in abs, penetration height)
--  or positive (actual distance to ground), always abs clamped to tile_size+1
-- if both sensors have different signed distances,
--  the lowest signed distance is returned (to escape completely or to have just 1 sensor snapping to the ground)
function player_character:_compute_ground_sensors_signed_distance(center_position)

  -- initialize with negative value to return if the character is not intersecting ground
  local min_signed_distance = 1 / 0  -- max (32768, but never enter it manually as it would be negative)

  -- check both ground sensors for ground. if any finds ground, return true
  for i in all({horizontal_directions.left, horizontal_directions.right}) do

    -- check that ground sensor #i is on top of or below the mask column
    local sensor_position = self:_get_ground_sensor_position_from(center_position, i)
    -- print("sensor_position: "..sensor_position)
    local signed_distance = self:_compute_signed_distance_to_closest_ground(sensor_position)
    -- print("signed_distance: "..signed_distance)

    -- store the biggest penetration height among sensors
    if signed_distance < min_signed_distance then
      min_signed_distance = signed_distance
    end

  end

  return min_signed_distance

end

-- return signed distance to closest ground from sensor_position,
--  either negative when (in abs, penetration height)
--  or positive (actual distance to ground), always abs clamped to tile_size+1
function player_character:_compute_signed_distance_to_closest_ground(sensor_position)

  -- find the tile where this sensor is located
  local sensor_location = sensor_position:to_location()

  -- get column on the collision mask that the ground sensor should check (ground sensor extent x
  --  should be in 0.5 and the 0.5->1 rounding should apply automatically due to flooring)
  -- note that this is slightly suboptimal as we won't use column_index0 at all if _compute_column_height_at returns early

  local sensor_location_topleft = sensor_location:to_topleft_position()
  local sensor_relative_x = sensor_position.x - sensor_location_topleft.x
  local column_index0 = flr(sensor_relative_x)  -- from 0 to tile_size - 1
  local ground_column_height = self:_compute_column_height_at(sensor_location, column_index0)

  -- compute relative height of sensor from tile bottom (y axis is downward)
  local sensor_location_bottom = sensor_location_topleft.y + tile_size
  local sensor_height = sensor_location_bottom - sensor_position.y
  assert(sensor_height > 0, "player_character:_compute_signed_distance_to_closest_ground: sensor_height is not positive, yet it was computed using sensor_position:to_location() which should always select a tile where the sensor is strictly above the bottom")

  -- check that ground sensor #i is on top of or below the mask column
  local signed_distance = sensor_height - ground_column_height
  -- print("ground_column_height: "..ground_column_height)
  -- print("signed_distance 2: "..signed_distance)

  -- note: if character is inside a tile but his feet are just at the bottom of this tile
  --  and the signed distance will be computed by checking any tile below (if no tile, will be tile_size+1)
  -- so always add a solid ground below a step up or a slope to avoid the character falling there
  -- if you want to check that case as well, check if sensor_height == tile_size, and in this case
  --  check the tiles above first, e.g. using _compute_stacked_column_height_above

  if ground_column_height == tile_size then
    -- column is full (reaches the top of the tile), we must check if there are any tiles
    --  stacked on top of this one, in which case the penetration height will be incremented by everything above (up to a limit of tile_size, so we clamp
    --  the added value by tile_size minus what we've already got)
    assert(signed_distance <= 0, "player_character:_compute_signed_distance_to_closest_ground: column is full yet sensor is considered above it")
    signed_distance = signed_distance - self:_compute_stacked_column_height_above(sensor_location, column_index0, tile_size + signed_distance)
    -- print("signed_distance 3: "..signed_distance)
  elseif ground_column_height == 0 then
    -- column is empty, check for more space below, up to a tile size
    assert(signed_distance >= 0, "player_character:_compute_signed_distance_to_closest_ground: column is empty yet sensor is considered below it")
    signed_distance = signed_distance + self:_compute_stacked_empty_column_height_below(sensor_location, column_index0, tile_size - signed_distance)
    -- print("signed_distance 4: "..signed_distance)
  end

  return signed_distance

end

-- return the sum of column heights of colliding tiles starting from the tile
--  just above the passed bottom_tile_location, all along the passed column_index0, up to the first tile
--  that is either outside the map or has not a full column (column height < tile size).
-- if the upper_limit is overrun during the loop before a non-full column is found, however,
--  return the upper_limit + 1
-- this method is important to compute the penetration height/escape distance to escape from multiple stacked tiles at once
function player_character:_compute_stacked_column_height_above(bottom_tile_location, column_index0, upper_limit)

  local stacked_column_height = 0
  local current_tile_location = bottom_tile_location:copy()

  while true do

    -- move 1 tile up from the start
    current_tile_location.j = current_tile_location.j - 1

    local ground_array_height = self:_compute_column_height_at(current_tile_location, column_index0)

    -- add column height to total (may be 0, in which case we'll break below)
    stacked_column_height = stacked_column_height + ground_array_height

    if stacked_column_height > upper_limit then
      return upper_limit + 1
    end

    -- stop if this tile has not a full column
    if ground_array_height < tile_size then
      break
    end

  end

  return stacked_column_height

end

-- return the sum of complementary column heights (height measured from top on negative tile collision mask)
--  of colliding tiles starting from the tile just below the passed top_tile_location,
--  all along the passed column_index0, down to the first solid tile having a non-empty column there
-- if the upper_limit is overrun during the loop before a non-empty column is found, however,
--  return the upper_limit + 1. this also will in particular prevent infinite loops
function player_character:_compute_stacked_empty_column_height_below(top_tile_location, column_index0, upper_limit)

  local stacked_empty_column_height = 0
  local current_tile_location = top_tile_location:copy()

  while true do

    -- move 1 tile up from the start
    current_tile_location.j = current_tile_location.j + 1

    local ground_array_height = self:_compute_column_height_at(current_tile_location, column_index0)

    -- add complementary height (empty space above column, may be 0, in which case we'll break below)
    stacked_empty_column_height = stacked_empty_column_height + (tile_size - ground_array_height)

    if stacked_empty_column_height > upper_limit then
      return upper_limit + 1
    end

    -- stop if this tile has not a full column
    if ground_array_height > 0 then
      break
    end

  end

  return stacked_empty_column_height

end

-- return the column height at tile_location on column_index0
function player_character:_compute_column_height_at(tile_location, column_index0)

  -- only consider valid tiles; consider there are no colliding tiles outside the map area
  if tile_location.i >= 0 and tile_location.i < 128 and tile_location.j >= 0 and tile_location.j < 64 then

    -- check if that tile at tile_location has a collider (mget will return 0 if there is no tile,
    --  so we must make the "empty" sprite 0 has no flags set)
    local current_tile_id = mget(tile_location.i, tile_location.j)
    local current_tile_collision_flag = fget(current_tile_id, sprite_flags.collision)
    if current_tile_collision_flag then

      -- get the tile collision mask
      local collision_mask_id_location = collision_data.sprite_id_to_collision_mask_id_locations[current_tile_id]
      assert(collision_mask_id_location, "sprite_id_to_collision_mask_id_locations does not contain entry for sprite id: "..current_tile_id..", yet it has the collision flag set")

      if collision_mask_id_location then
        -- possible optimize: cache collision height array on game start
        -- todo: get slope angle from data and pass it as 2nd argument
        local h_array = collision.height_array(collision_mask_id_location, 0)
        return h_array:get_height(column_index0)
      end

    end

  end

  return 0

end

-- escape from ground if needed, and update motion state if needed based on ground sensed or not
function player_character:_check_escape_from_ground_and_update_motion_state()
  local is_ground_sensed = self:_check_escape_from_ground()
  self:_update_platformer_motion_state(is_ground_sensed)
end

-- verifies if character is inside ground, and push him upward outside if inside but not too deep inside
-- return true iff the character was either touching the ground or inside it (even too deep)
function player_character:_check_escape_from_ground()
  local signed_distance_to_closest_ground = self:_compute_signed_distance_to_closest_ground(self.position)
  if signed_distance_to_closest_ground < 0 and abs(signed_distance_to_closest_ground) <= playercharacter_data.max_ground_escape_height then
    self:move(vector(0, signed_distance_to_closest_ground))
  end
  return signed_distance_to_closest_ground <= 0
end

-- function player_character:_get_ground_sensor_position(horizontal_dir)
--   -- ignore subpixels on x for ground detection
--   local bottom_center = self:get_bottom_center()
--   local pixel_perfect_bottom_center = vector(flr(bottom_center.x), bottom_center.y)
--   local right_offset = vector(playercharacter_data.ground_sensor_extent_x, 0)

--   if horizontal_dir == horizontal_directions.left then
--     return pixel_perfect_bottom_center - right_offset
--   else
--     return pixel_perfect_bottom_center + right_offset
--   end
-- end

-- return the position of the ground sensor in horizontal_dir when the character center is at center_position
function player_character:_get_ground_sensor_position_from(center_position, horizontal_dir)
  local bottom_center = center_position + vector(0, playercharacter_data.center_height_standing)
  -- REFACTOR: we may also floor the coord x at the beginning of _compute_next_position_from_ground
  -- once and for all

  -- ignore subpixels on x for ground detection
  local pixel_perfect_bottom_center = vector(flr(bottom_center.x), bottom_center.y)
  local right_offset = vector(playercharacter_data.ground_sensor_extent_x, 0)
  -- print("bottom_center: "..bottom_center)
  -- print("pixel_perfect_bottom_center: "..pixel_perfect_bottom_center)
  -- print("right_offset: "..right_offset)

  if horizontal_dir == horizontal_directions.left then
    -- print("left")
    -- print("pixel_perfect_bottom_center - right_offset: "..pixel_perfect_bottom_center - right_offset)
    return pixel_perfect_bottom_center - right_offset
  else
    -- print("right")
    -- print("pixel_perfect_bottom_center + right_offset: "..pixel_perfect_bottom_center + right_offset)
    return pixel_perfect_bottom_center + right_offset
  end
end

-- return the position of the wall sensor in horizontal_dir when the character center is at center_position
function player_character:_get_wall_sensor_position_from(center_position, horizontal_dir)
  local bottom_center = center_position + vector(0, playercharacter_data.center_height_standing)
  -- REFACTOR: we may also floor the coord x at the beginning of _compute_next_position_from_ground
  -- once and for all

  -- ignore subpixels on x for ground detection
  local pixel_perfect_bottom_center = vector(flr(bottom_center.x), bottom_center.y)
  local right_offset = vector(playercharacter_data.wall_sensor_extent_x, 0)

  if horizontal_dir == horizontal_directions.left then
    return pixel_perfect_bottom_center - right_offset
  else
    return pixel_perfect_bottom_center + right_offset
  end
end

-- update motion state based on whether ground was sensed this frame
function player_character:_update_platformer_motion_state(is_ground_sensed)
  if self.motion_state == motion_states.grounded then
    if not is_ground_sensed then
      -- we have just left the ground, enter airborne state
      --  and since ground speed is now unused, reset it for clarity
      self.motion_state = motion_states.airborne
      self.ground_speed_frame = 0
    end
  end

  if self.motion_state == motion_states.airborne then
    if is_ground_sensed then
      -- we have just reached the ground (and possibly escaped),
      --  reset values airborne vars
      self.motion_state = motion_states.grounded
      self.velocity_frame.y = 0  -- no velocity retain yet on y
      self.has_interrupted_jump = false
    end
  end
end

-- update velocity and position based on current motion state
function player_character:_update_platformer_motion()
  if self.motion_state == motion_states.grounded then
    self:_update_platformer_motion_grounded()
  elseif self.motion_state == motion_states.airborne then
    self:_update_platformer_motion_airborne()
  end
end

-- update motion following platformer grounded motion rules
function player_character:_update_platformer_motion_grounded()
  -- ground speed
  self:_update_ground_speed()
  -- self:_update_velocity_grounded()

  -- optimize: if ground_speed == 0, we can skip the whole motion
  local horizontal_dir = self.ground_speed_frame < 0 and horizontal_directions.left or horizontal_directions.right
  local next_position, next_velocity, next_motion_state = self:_compute_next_position_from_ground(horizontal_dir, self.ground_speed_frame)

  -- jump speed
  -- unlike classic Sonic, we apply jump after motion so we can increase position and velocity
  --  for an optimal jump (SPG: Jumping mentions that jump check is done early and returns)
  -- note that we are not checking if the ground will be left with the ground motion this frame,
  --  effectively allowing the player to confirm jump the frame the character leaves the ground (late jump)
  local is_jumping = self:_check_jump()
  if is_jumping then
    -- don't care about future obstacles, just set the nominative velocity
    self:_update_velocity_grounded()
    -- move (including jump speed y)
    self:move(self.velocity_frame)
  else
    self.position = next_position
    self.velocity_frame = next_velocity
    self:_update_platformer_motion_state(next_motion_state)
  end


  if not is_jumping then
    -- character is not leaving the ground, so update position following current ground curve
    --  by always snapping to the ground vertically
    -- note than on convex slope masks, this will move the character a bit faster,
    --  and on concave slope masks, a bit slower than we would expect with a pixel-based
    --  curviline estimation (because the velocity is based on an average slope)

    -- not needed if motion is pixel perfect already
    -- self:_snap_to_ground()

    if self.motion_state == motion_states.grounded then
      -- character is still on ground, prepare for any jump next frame
      -- note that we are not forbidding jump when character is too deep inside the ground
      --  if it allows the character to jump out of this abnormal case, that's fine
      self:_check_jump_intention()
    end
  end
end

-- update ground speed based on current move intention
function player_character:_update_ground_speed()
  if self.move_intention.x ~= 0 then
    if self.ground_speed_frame == 0 or sgn(self.ground_speed_frame) == sgn(self.move_intention.x) then
      -- accelerate
      self.ground_speed_frame = self.ground_speed_frame + self.move_intention.x * playercharacter_data.ground_accel_frame2
    else
      -- decelerate
      self.ground_speed_frame = self.ground_speed_frame + self.move_intention.x * playercharacter_data.ground_decel_frame2
      -- if speed must switch sign this frame, clamp it by ground accel in absolute value to prevent exploit of
      --  moving back 1 frame then forward to gain an initial speed boost (mentioned in Sonic Physics Guide as a bug)
      local has_changed_sign = self.ground_speed_frame ~= 0 and sgn(self.ground_speed_frame) == sgn(self.move_intention.x)
      if has_changed_sign and abs(self.ground_speed_frame) > playercharacter_data.ground_accel_frame2 then
        self.ground_speed_frame = sgn(self.ground_speed_frame) * playercharacter_data.ground_accel_frame2
      end
    end
  elseif self.ground_speed_frame ~= 0 then
    -- friction
    self.ground_speed_frame = sgn(self.ground_speed_frame) * max(0, abs(self.ground_speed_frame) - playercharacter_data.ground_friction_frame2)
  end
end

-- update velocity based on ground speed
function player_character:_update_velocity_grounded()
  -- only support flat ground for now
  self.velocity_frame = vector(self.ground_speed_frame, 0)
end

-- return (next_position, next_motion_state) where
--  next_position is the next position if the character is moving on quadrant 0
--  along horizontal_dir, at ground_speed, from the current position;
--  next_motion_state is 'airborne' if the character will leave ground, else 'grounded'
-- the computation takes the slope of the ground into account to reduce
--  ground_speed by a factor if applicable
-- it also distinguishes step-ups from walls (that are step-ups "too high")
-- the next position is said "ground position" because motion follows ground,
--  but may be in the air
-- we assume the character is already on ground. if he's not, the method will still work,
--  the character will simply try to move to the next columns in this tile from his current
--  position, and if the columns are empty, he will look for the tile below (and fall
--  of the step down is too high, which is very likely)
function player_character:_compute_next_position_from_ground(horizontal_dir, ground_speed)
  -- identify the current ground tile
  -- get column height array and slope
  -- compute the distance to run over x based on ground speed and slope
  -- iterate over the columns over that distance, checking for step-up/wall each step
  -- if you leave the current tile by moving on x, just move to the next tile and repeat as long
  --  as there is some distance left to travel
  -- if a column is full or empty, check the tile above or below, then continue iterating
  --  from that new height

  -- return self.position, motion_states.grounded
  -- maybe update in-place

  -- count on flooring inside _compute_signed_distance_to_closest_ground...
  local last_position_candidate = self.position
  local next_position_candidate
  local horizontal_dir_v = horizontal_direction_vectors[horizontal_dir]
  -- printh(stringify(horizontal_dir_v))

  local is_blocked = false
  local is_airborne = false

  -- todo: fill this with tile data
  local slope_cos = 1
  local slope_sin = 0
  local distance = 0
  local max_distance = abs(ground_speed) * slope_cos
  while distance < max_distance do
    -- todo:
    next_position_candidate = last_position_candidate + horizontal_dir_v
    -- printh("next_position_candidate: "..stringify(next_position_candidate))
    distance = distance + 1 * slope_cos

    -- first check if there is a wall where we're going
    local wall_sensor_forward = self:_get_wall_sensor_position_from(next_position_candidate)
    local signed_distance_to_closest_ground = self:_compute_signed_distance_to_closest_ground(wall_sensor_forward)

    -- if signed_distance_to_closest_ground > playercharacter_data.max_ground_escape_height then
    --   -- we've met a step up too high, i.e. a wall, stop
    --   is_blocked = true
    --   -- optionally clamp the position to the wall (classic Sonic doesn't)
    --   last_position_candidate = vector(flr(last_position_candidate.x), last_position_candidate.y)
    --   break
    -- end

    -- or recompute distance from the start position to avoid accumulation errors
    local signed_distance_to_closest_ground = self:_compute_ground_sensors_signed_distance(next_position_candidate)

    if signed_distance_to_closest_ground < 0 then
      local penetration_height = - signed_distance_to_closest_ground
      if penetration_height <= playercharacter_data.max_ground_escape_height then
        -- move up the future position prediction point
        last_position_candidate = next_position_candidate - vector(0, penetration_height)
        -- if we left the ground "in the middle of the frame", snap back to ground
        is_airborne = false
      else
        -- todo: actually, wall sensor are 1px farther than ground sensor,
        --  so we'd need _compute_signed_distance_to_closest_ground to check both
        --  distances... to detect wall like here, the farther sensor, and to detect fall like above
        --  and slo for snapping up/down, the ground sensor...
        -- for now, we use the same for both
        -- we've met a step up too high, i.e. a wall, stop
        is_blocked = true
        -- optionally clamp the position to the wall (classic Sonic doesn't)
        -- last_position_candidate = vector(flr(last_position_candidate.x), last_position_candidate.y)

        -- just pop the character out when needed
        -- this way, cannot walk on will always be equivalent to "this is a wall"
        -- and the step up check will always be between neighboring columns heights, never in advance of 2px
        last_position_candidate = vector(flr(last_position_candidate.x) - wall_sensor_extent_x + ground_sensor_extent_x, last_position_candidate.y)
        break
      end
    elseif signed_distance_to_closest_ground > 0 then
      if signed_distance_to_closest_ground <= playercharacter_data.max_ground_snap_height then
        -- move down the future position prediction point
        last_position_candidate = next_position_candidate + vector(0, signed_distance_to_closest_ground)
        -- if we left the ground "in the middle of the frame", snap back to ground
        -- and do as nothing happened
        is_airborne = false
      else
        -- character was in the air and couldn't snap back to ground (cliff, etc.),
        is_airborne = true
        -- this doesn't mean that the motion is over yet... it's rare,
        -- but the character could snap back on ground. in most cases he'll just
        -- run a little farther in the air
        -- since we have no reference, we just continue running along the same direction (slope)
        -- every step
        -- beware sinus orientation convention
        last_position_candidate = next_position_candidate + vector(0, ground_speed * slope_sin)
      end
    else
      last_position_candidate = next_position_candidate
    end
    -- printh("last_position_candidate: "..stringify(last_position_candidate))
  end

  -- printh("b: "..stringify(is_blocked))
  -- printh("a: "..stringify(is_airborne))

  local next_velocity
  if is_blocked then
    -- self.velocity = vector.zero()
    next_velocity = vector.zero()
  else
    next_velocity = vector(ground_speed * slope_cos, ground_speed * slope_sin)
  end
  -- printh("next_velocity: "..stringify(next_velocity))
  -- printh("last_position_candidate: "..stringify(last_position_candidate))

  local next_motion_state
  if is_airborne then
    -- self:_update_platformer_motion_state(false)
    next_motion_state = motion_states.airborne
  else
    next_motion_state = motion_states.grounded
  end

  return last_position_candidate, next_velocity, next_motion_state
end

-- if character intends to jump, prepare jump for next frame
-- this extra frame allows us to detect if the player wants a variable jump or a hop
--  depending whether input is hold or not
function player_character:_check_jump_intention()
  if self.jump_intention then
    self.jump_intention = false
    self.should_jump = true
  end
end

-- if character intends to jump, apply jump velocity from current ground
--  and enter the airborne state
-- return true iff jump was applied
function player_character:_check_jump()
  if self.should_jump then
    self.should_jump = false

    -- compute initial jump speed based on whether player is still holding jump button
    local initial_jump_speed
    if self.hold_jump_intention then
      -- variable jump
      initial_jump_speed = playercharacter_data.initial_var_jump_speed_frame
    else
      -- hop
      initial_jump_speed = playercharacter_data.jump_interrupt_speed_frame
    end

    -- only support flat ground for now
    self.velocity_frame.y = self.velocity_frame.y - initial_jump_speed
    self:_update_platformer_motion_state(false)
    return true
  end
  return false
end

-- set the player position y so that one ground sensor is just on top of the current tile,
--  or the one above if the character is inside ground with one sensor at a full mask column,
--  or the one below if the character is above ground with both sensors at empty mask colums
-- if character is in the air and couldn't snap, enter airborne state
function player_character:_snap_to_ground()
  local signed_distance_to_closest_ground = self:_compute_signed_distance_to_closest_ground(self.position)
  if signed_distance_to_closest_ground < 0 then
    local penetration_height = - signed_distance_to_closest_ground
    if penetration_height <= playercharacter_data.max_ground_escape_height then
      self:move(vector(0, signed_distance_to_closest_ground))  -- move up
    end
  elseif signed_distance_to_closest_ground > 0 then
    if signed_distance_to_closest_ground <= playercharacter_data.max_ground_snap_height then
      self:move(vector(0, signed_distance_to_closest_ground))  -- move down
    else
      -- character was in the air and couldn't snap back to ground (cliff, etc.),
      --  so enter airborne state now
      self:_update_platformer_motion_state(false)
    end
  end
end

-- update motion following platformer airborne motion rules
function player_character:_update_platformer_motion_airborne()
  -- check if player is continuing or interrupting jump *before* applying gravity
  --  since our playercharacter_data.jump_interrupt_speed_frame is defined to be applied before gravity
  self:_check_hold_jump()

  -- apply gravity to current speed y
  self.velocity_frame.y = self.velocity_frame.y + playercharacter_data.gravity_frame2

  -- apply x acceleration via intention (if not 0)
  self.velocity_frame.x = self.velocity_frame.x + self.move_intention.x * playercharacter_data.air_accel_x_frame2

  -- apply air motion
  self:move(self.velocity_frame)

  -- detect ground and snap up for landing
  self:_check_escape_from_ground_and_update_motion_state()
end

-- check if character wants to interrupt jump by not holding anymore,
--  and set vertical speed to interrupt speed if so
function player_character:_check_hold_jump()
  if not self.has_interrupted_jump and not self.hold_jump_intention then
    -- character has not interrupted jump yet and wants to
    -- flag jump as interrupted even if it's too late, so we don't enter this block anymore
    self.has_interrupted_jump = true

    -- character tries to interrupt jump, check if's not too late
    local signed_jump_interrupt_speed_frame = -playercharacter_data.jump_interrupt_speed_frame
    if self.velocity_frame.y < signed_jump_interrupt_speed_frame then
      self.velocity_frame.y = signed_jump_interrupt_speed_frame
    end
  end
end

-- update the velocity and position of the character following debug motion rules
function player_character:_update_debug()
  self:_update_velocity_debug()
  self:move(self.debug_velocity * delta_time)
end

function player_character:_update_velocity_debug()
  -- update velocity from input
  -- in debug mode, cardinal speeds are independent and max speed applies to each
  self:_update_velocity_component_debug("x")
  self:_update_velocity_component_debug("y")
end

-- update the velocity component for coordinate "x" or "y" with debug motion
-- coord  string  "x" or "y"
function player_character:_update_velocity_component_debug(coord)
  if self.move_intention[coord] ~= 0 then
    -- some input => accelerate (direction may still change or be opposed)
    local clamped_move_intention_comp = mid(-1, self.move_intention[coord], 1)
    self.debug_velocity[coord] = self.debug_velocity[coord] + self.debug_move_accel * delta_time * clamped_move_intention_comp
    self.debug_velocity[coord] = mid(-self.debug_move_max_speed, self.debug_velocity[coord], self.debug_move_max_speed)
  else
    -- no input => decelerate
    if self.debug_velocity[coord] ~= 0 then
      self.debug_velocity[coord] = sgn(self.debug_velocity[coord]) * max(abs(self.debug_velocity[coord]) - self.debug_move_decel * delta_time, 0)
    end
  end
end

-- move the player character so that the bottom center is at the given position
function player_character:get_bottom_center()
  return self.position + vector(0, playercharacter_data.center_height_standing)
end

-- move the player character so that the bottom center is at the given position
function player_character:set_bottom_center(bottom_center_position)
  self.position = bottom_center_position - vector(0, playercharacter_data.center_height_standing)
end

-- move the player character from delta_vector in px
function player_character:move(delta_vector)
  self.position = self.position + delta_vector
end

-- render the player character sprite at its current position
function player_character:render()
 self.spr_data:render(self.position)
end

return player_character
