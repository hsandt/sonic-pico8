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

-- spr_data               sprite_data   sprite data
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

  self:_setup()
end

function player_character:_setup()
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

-- spawn character at given position, and escape from ground / enter airborne state if needed
function player_character:spawn_at(position)
  self:_setup()

  self.position = position

  -- character is initialized grounded, but let him fall if he is spawned in the air
  local is_grounded = self:_check_escape_from_ground()
  if not is_grounded then
    self:_enter_motion_state(motion_states.airborne)
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
function player_character:move_by(delta_vector)
  self.position = self.position + delta_vector
end

-- update player position
function player_character:update()
  if self.motion_mode == motion_modes.platformer then
    self:_update_platformer_motion()
  else  -- self.motion_mode == motion_modes.debug
    self:_update_debug()
  end
end

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
    local signed_distance = self:_compute_signed_distance_to_closest_ground(sensor_position)

    -- store the biggest penetration height among sensors
    if signed_distance < min_signed_distance then
      min_signed_distance = signed_distance
    end

  end

  return min_signed_distance

end

-- return the position of the ground sensor in horizontal_dir when the character center is at center_position
-- subpixels are ignored
function player_character:_get_ground_sensor_position_from(center_position, horizontal_dir)
  -- ignore subpixels from center position in x
  local x_floored_center_position = vector(flr(center_position.x), center_position.y)
  local x_floored_bottom_center = x_floored_center_position + vector(0, playercharacter_data.center_height_standing)

  -- using a ground_sensor_extent_x in .5 and flooring +/- this value allows us to get the checked column x (the x corresponds to the left of that column)
  local offset_x = flr(horizontal_direction_signs[horizontal_dir] * playercharacter_data.ground_sensor_extent_x)

  return x_floored_bottom_center + vector(offset_x, 0)
end

-- return signed distance to closest ground from floored sensor_position,
--  either negative when (in abs, penetration height)
--  or positive (actual distance to ground), always abs clamped to tile_size+1
function player_character:_compute_signed_distance_to_closest_ground(sensor_position)

  assert(flr(sensor_position.x) == sensor_position.x, "player_character:_compute_signed_distance_to_closest_ground: sensor_position.x must be floored")

  -- find the tile where this sensor is located
  local sensor_location = sensor_position:to_location()

  -- get column on the collision mask that the ground sensor should check (ground sensor extent x
  --  should be in 0.5 and the 0.5->1 rounding should apply automatically due to flooring)
  -- note that we won't use column_index0 in _compute_column_height_at if there is no collision tile around,
  --  but its computation is cheap

  local sensor_location_topleft = sensor_location:to_topleft_position()
  local column_index0 = sensor_position.x - sensor_location_topleft.x  -- from 0 to tile_size - 1
  local ground_column_height = self:_compute_column_height_at(sensor_location, column_index0)

  -- compute relative height of sensor from tile bottom (y axis is downward)
  local sensor_location_bottom = sensor_location_topleft.y + tile_size
  local sensor_height = sensor_location_bottom - sensor_position.y
  assert(sensor_height > 0, "player_character:_compute_signed_distance_to_closest_ground: sensor_height is not positive, yet it was computed using sensor_position:to_location() which should always select a tile where the sensor is strictly above the bottom")

  -- check that ground sensor #i is on top of or below the mask column
  local signed_distance = sensor_height - ground_column_height

  -- note: if character is inside a tile but his feet are just at the bottom of this tile
  --  and the signed distance will be computed by checking any tile below (if no tile, will be tile_size+1)
  -- so always add a solid ground below a step up or a slope to avoid the character falling there
  -- if you want to check that case as well, check if sensor_height == tile_size, and in this case
  --  check the tiles above first, e.g. using _compute_stacked_column_height_above

  -- however, the best is to solve the more general problem of detecting tiles at the upper level
  --  of the character. for instance, he may walk from a bottom half-tile toward a full tile one tile higher
  --  in which case checking sensor_height == tile_size won't help, yet the character's head would bump into the
  --  ceiling and the character should stop. so we'll need to check all extra column heights above step-up level
  --  that may overlap the character's new position (using his colliding height)

  -- note that even classic Sonic only checks ceiling when moving up, but being blocked
  --  by all kinds of high step ups when moving horizontally is still important and classic Sonic does it

  if ground_column_height == tile_size then
    -- column is full (reaches the top of the tile), we must check if there are any tiles
    --  stacked on top of this one, in which case the penetration height will be incremented by everything above (up to a limit of tile_size, so we clamp
    --  the added value by tile_size minus what we've already got)
    assert(signed_distance <= 0, "player_character:_compute_signed_distance_to_closest_ground: column is full yet sensor is considered above it")
    signed_distance = signed_distance - self:_compute_stacked_column_height_above(sensor_location, column_index0, tile_size + signed_distance)
  elseif ground_column_height == 0 then
    -- column is empty, check for more space below, up to a tile size
    assert(signed_distance >= 0, "player_character:_compute_signed_distance_to_closest_ground: column is empty yet sensor is considered below it")
    signed_distance = signed_distance + self:_compute_stacked_empty_column_height_below(sensor_location, column_index0, tile_size - signed_distance)
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

-- verifies if character is inside ground, and push him upward outside if inside but not too deep inside
-- return true iff the character was either touching the ground or inside it (even too deep)
function player_character:_check_escape_from_ground()
  local signed_distance_to_closest_ground = self:_compute_ground_sensors_signed_distance(self.position)
  if signed_distance_to_closest_ground < 0 and abs(signed_distance_to_closest_ground) <= playercharacter_data.max_ground_escape_height then
    self.position.y = self.position.y + signed_distance_to_closest_ground
  end
  return signed_distance_to_closest_ground <= 0
end

-- enter motion state, reset state vars appropriately
function player_character:_enter_motion_state(next_motion_state)
  self.motion_state = next_motion_state
  if next_motion_state == motion_states.airborne then
    -- we have just left the ground, enter airborne state
    --  and since ground speed is now unused, reset it for clarity
    self.ground_speed_frame = 0
    self.should_jump = false
  elseif next_motion_state == motion_states.grounded then
    -- we have just reached the ground (and possibly escaped),
    --  reset values airborne vars
    self.velocity_frame.y = 0  -- no velocity retain yet on y
    self.has_interrupted_jump = false
  end
end

-- update velocity, position and state based on current motion state
function player_character:_update_platformer_motion()
  -- check for jump before apply motion, so character can jump at the beginning of the motion
  --  (as in classic Sonic), but also apply an initial impulse if character starts idle and
  --  left/right is pressed just when jumping (to fix classic Sonic missing a directional input frame there)
  if self.motion_state == motion_states.grounded then
    self:_check_jump()  -- this may change the motion state to airborne
  end

  if self.motion_state == motion_states.grounded then
    self:_update_platformer_motion_grounded()
  else  -- self.motion_state == motion_states.airborne
    self:_update_platformer_motion_airborne()
  end
end

-- update motion following platformer grounded motion rules
function player_character:_update_platformer_motion_grounded()
  self:_update_ground_speed()
  local ground_motion_result = self:_compute_ground_motion_result()
  self.position = ground_motion_result.position

  if ground_motion_result.is_blocked then
    self.velocity_frame = vector.zero()
  else
    self.velocity_frame = vector(self.ground_speed_frame, 0)
  end

  if ground_motion_result.is_falling then
    self:_enter_motion_state(motion_states.airborne)
  else
    self:_check_jump_intention()
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

-- return {next_position: vector, is_blocked: bool, is_falling: bool} where
--  - next_position is the position of the character next frame considering his current ground speed
--  - is_blocked is true iff the character encounters a wall during this motion
--  - is_falling is true iff the character leaves the ground just by running during this motion
function player_character:_compute_ground_motion_result()
  -- if character is not moving, he is not blocked nor falling (we assume the environment is static)
  if self.ground_speed_frame == 0 then
    return collision.ground_motion_result(
      self.position,
      false,
      false
    )
  end

  local horizontal_dir = signed_speed_to_direction(self.ground_speed_frame)

  -- initialise result
  local motion_result = collision.ground_motion_result(
    vector(flr(self.position.x), self.position.y),
    false,
    false
  )

  -- only full pixels matter for collisions, but subpixels may sum up to a full pixel
  --  so first estimate how many full pixel columns the character may actually explore this frame
  local max_column_distance = self._compute_max_column_distance(self.position.x, self.ground_speed_frame)

  -- iterate pixel by pixel on the x direction until max possible distance is reached
  --  only stopping if the character is blocked by a wall (not if falling, since we want
  --  him to continue moving in the air as far as possible; in edge cases, he may even
  --  touch the ground again some pixels farther)
  local column_distance = 1
  while column_distance <= max_column_distance and not motion_result.is_blocked do
    self:_next_ground_step(horizontal_dir, motion_result)
    column_distance = column_distance + 1
  end

  -- check if we need to add or cut subpixels
  if not motion_result.is_blocked then
    local are_subpixels_left = self.position.x + self.ground_speed_frame > motion_result.position.x
    if are_subpixels_left then
      -- character has not been blocked and has some subpixels left to go
      -- check if character has touched a wall (we need an extra step to "ceil" the subpixels)
      local extra_step_motion_result = motion_result:copy()
      self:_next_ground_step(horizontal_dir, extra_step_motion_result)
      if extra_step_motion_result.is_blocked then
        -- character has just reached a wall, plus a few subpixels
        -- unlike Classic Sonic, we decide to cut the subpixels and block the character
        --  on the spot (we just reuse the result of the extra step, since is_falling doesn't change if is_blocked is true)
        motion_result = extra_step_motion_result
      else
        -- character has not touched a wall at all, so add the remaining subpixels
        --  (it's simpler to just recompute the full motion in x; don't touch y tough,
        --  as it depends on the shape of the ground)
        motion_result.position.x = self.position.x + self.ground_speed_frame
      end
    end
  end

  return motion_result
end

-- return the number of new pixel columns explored when moving from initial_position_x
--  over ground_speed_frame * 1 frame. this is either flr(ground_speed_frame)
--  or flr(ground_speed_frame) + 1 (if subpixels from initial position x and speed sum up to 1.0 or more)
function player_character._compute_max_column_distance(initial_position_x, ground_speed_frame)
  return abs(flr(initial_position_x + ground_speed_frame) - flr(initial_position_x))
end

-- update motion_result: collision.ground_motion_result for a character trying to move
--  by 1 pixel step in horizontal_dir, taking obstacles into account
-- if character is blocked, it doesn't update the position and flag is_blocked
-- if character is fallling, it updates the position and flag is_falling
-- ground_motion_result.position.x should be floored for these steps
--  although _compute_ground_sensors_signed_distance will floor in x anyway
function player_character:_next_ground_step(horizontal_dir, motion_result)
  -- compute candidate position on next step. only flat slopes supported
  local step_vec = horizontal_direction_vectors[horizontal_dir]
  local next_position_candidate = motion_result.position + step_vec

  -- check if next position is inside/above ground
  local signed_distance_to_closest_ground = self:_compute_ground_sensors_signed_distance(next_position_candidate)
  if signed_distance_to_closest_ground < 0 then
    -- position is inside ground, check if we can step up during this step
    local penetration_height = - signed_distance_to_closest_ground
    if penetration_height <= playercharacter_data.max_ground_escape_height then
      -- step up
      next_position_candidate.y = next_position_candidate.y - penetration_height
      -- if we left the ground during a previous step, cancel that (step up land, very rare)
      motion_result.is_falling = false
    else
      -- step blocked: step up is too high, character is blocked
      -- if character left the ground during a previous step, let it this way;
      --  character will simply hit the wall, then fall
      motion_result.is_blocked = true
    end
  elseif signed_distance_to_closest_ground > 0 then
    -- position is above ground, check if we can step down during this step
    if signed_distance_to_closest_ground <= playercharacter_data.max_ground_snap_height then
      -- step down
      next_position_candidate.y = next_position_candidate.y + signed_distance_to_closest_ground
      -- if character left the ground during a previous step, cancel that (step down land, very rare)
      motion_result.is_falling = false
    else
      -- step fall: step down is too low, character will fall
      -- in some rare instances, character may find ground again farther, so don't stop the outside loop yet
      motion_result.is_falling = true
    end
  else
    -- step flat
    -- if character left the ground during a previous step, cancel that (very rare)
    motion_result.is_falling = false
  end

  -- character is not blocked by a steep step up/wall, but we need to check if it is
  --  blocked by a ceiling too low; in the extreme case, a diagonal tile pattern
  --  ->X
  --   X
  if not motion_result.is_blocked then
    motion_result.is_blocked = self:_is_blocked_by_ceiling_at(next_position_candidate)

    -- only advance if character is still not blocked (else, preserve previous position,
    --  which should be floored)
    -- this only works because the wall sensors are 1px farther from the character
    --  center than the ground sensors; if there were even farther, we'd even need to
    --  move the position backward by hypothetical wall_sensor_extent_x - ground_sensor_extent_x - 1
    --  when motion_result.is_blocked (and adapt y)
    if not motion_result.is_blocked then
      motion_result.position = next_position_candidate
    end
  end
end

-- return true iff the character cannot stand in his full height (based on ground_sensor_extent_x)
--  at position because of the ceiling (or a full tile if standing at the top of a tile)
function player_character:_is_blocked_by_ceiling_at(center_position)

  -- check ceiling from both ground sensors. if any finds one, return true
  for i in all({horizontal_directions.left, horizontal_directions.right}) do

    -- check if ground sensor #i has ceiling closer than a character's height
    local sensor_position = self:_get_ground_sensor_position_from(center_position, i)
    if self:_is_column_blocked_by_ceiling_at(sensor_position) then
      return true
    end

  end

  return false
end

-- return true iff there is a ceiling above in the column of sensor_position, in a tile above
--  sensor_position's tile, within a height lower than a character's height
function player_character:_is_column_blocked_by_ceiling_at(sensor_position)

  assert(flr(sensor_position.x) == sensor_position.x, "player_character:_is_blocked_by_ceiling_at_column: sensor_position.x must be floored")

  -- find the tile where this sensor is located
  local current_tile_location = sensor_position:to_location()
  local sensor_location_topleft = current_tile_location:to_topleft_position()
  local column_index0 = sensor_position.x - sensor_location_topleft.x  -- from 0 to tile_size - 1

  while true do

    -- move 1 tile up from the start, as we can only hit ceiling from a tile above with non-rotated tiles
    -- note: when we add rotated tiles, we will need to handle ceiling tiles (tiles rotated by 180)
    --  starting from the current tile, because unlike ground tiles, they may actually block
    --  the character's head despite being in his current tile location
    -- so we'll need to move the decrement statement to the end of the loop and add a tile rotation check
    --  in addition we'll need to _compute_column_bottom_height_at() to handle variable ceiling height along a tile
    --  rather than just checking if _compute_column_height_at() > 0
    -- to avoid tile rotation check, we can also check if _compute_column_bottom_height_at() is lower than the feet (so we can ignore it)
    -- (90 and 270-rotated tiles will be ignored as they are not supposed to block the character's head)
    current_tile_location.j = current_tile_location.j - 1
    local current_tile_top = current_tile_location:to_topleft_position().y

    local ground_array_height = self:_compute_column_height_at(current_tile_location, column_index0)
    if ground_array_height > 0 then
      -- with non-rotated tiles, we are sure to hit the ceiling at this point
      --  because ceiling is always at a tile bottom, and we return false
      --  as soon as we go up farther than a character's height
      return true
      -- with ceiling tiles, we will need to check if the ceiling column height
      --  hits the head or not. if it doesn't stop here, return false,
      --  the head is below the ceiling:
      -- local current_tile_bottom = current_tile_top + tile_size
      -- local height_distance = sensor_position.y - current_tile_bottom
      -- return height_distance < playercharacter_data.full_height_standing
    end

    local height_distance = sensor_position.y - current_tile_top
    if height_distance >= playercharacter_data.full_height_standing then
      return false
    end

  end

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
      -- mark jump as interrupted so we don't check it again
      --  (optional, since we will never be able to interrupt such a small jump anyway)
      self.has_interrupted_jump = true
    end

    -- only support flat ground for now
    self.velocity_frame.y = self.velocity_frame.y - initial_jump_speed
    self:_enter_motion_state(motion_states.airborne)
    return true
  end
  return false
end

-- set the player position y so that one ground sensor is just on top of the current tile,
--  or the one above if the character is inside ground with one sensor at a full mask column,
--  or the one below if the character is above ground with both sensors at empty mask colums
-- if character is in the air and couldn't snap, enter airborne state
function player_character:_snap_to_ground()
  local signed_distance_to_closest_ground = self:_compute_ground_sensors_signed_distance(self.position)
  if signed_distance_to_closest_ground < 0 then
    local penetration_height = - signed_distance_to_closest_ground
    if penetration_height <= playercharacter_data.max_ground_escape_height then
      self.position.y = self.position.y + signed_distance_to_closest_ground  -- move up
    end
  elseif signed_distance_to_closest_ground > 0 then
    if signed_distance_to_closest_ground <= playercharacter_data.max_ground_snap_height then
      self.position.y = self.position.y + signed_distance_to_closest_ground  -- move down
    else
      -- character was in the air and couldn't snap back to ground (cliff, etc.),
      --  so enter airborne state now
      self:_enter_motion_state(motion_states.airborne)
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
  self:move_by(self.velocity_frame)

  -- detect ground and snap up for landing
  local has_landed = self:_check_escape_from_ground()
  if has_landed then
    self:_enter_motion_state(motion_states.grounded)
  end
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
  self:move_by(self.debug_velocity * delta_time)
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

-- render the player character sprite at its current position
function player_character:render()
 self.spr_data:render(self.position)
end

return player_character
