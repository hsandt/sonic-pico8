require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
require("engine/core/math")
require("engine/render/sprite")
local input = require("engine/input/input")
local collision = require("engine/physics/collision")
local world = require("engine/physics/world")
local pc_data = require("game/data/playercharacter_data")


-- enum for character control
control_modes = {
  human = 1,      -- player controls character
  ai = 2,         -- ai controls character
  puppet = 3      -- itest script controls character
}

-- motion_modes and motion_states are accessed dynamically via variant name in itest_dsl
--  so we don't strip them away from pico8 builds
-- it is only used for debug and expectations, though, so it could be #if cheat/test only,
--  but the dsl may be used for attract mode later (dsl) so unless we distinguish
--  parsable types like motion_states that are only used for expectations (and cheat actions)
--  as opposed to actions, we should keep this in the release build

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


local player_char = new_class()

-- parameters

-- spr_data               {string: sprite_data}   sprite data for this character
-- debug_move_max_speed   float                   move max speed in debug mode
-- debug_move_accel       float                   move acceleration in debug mode
-- debug_move_decel       float                   move deceleration in debug mode

-- state vars

-- control_mode           control_modes   control mode: human (default) or ai
-- motion_mode (cheat)    motion_modes    motion mode: platformer (under gravity) or debug (fly around)
-- motion_state           motion_states   motion state (platformer mode only)
-- horizontal_dir         horizontal_dirs direction faced by character
-- position               vector          current position (character center "between" pixels)
-- ground_speed           float           current speed along the ground (~px/frame)
-- velocity               vector          current velocity in platformer mode (px/frame)
-- debug_velocity         vector          current velocity in debug mode (m/s)
-- slope_angle            float           slope angle of the current ground (clockwise turn ratio)
-- move_intention         vector          current move intention (normalized)
-- jump_intention         bool            current intention to start jump (consumed on jump)
-- hold_jump_intention    bool            current intention to hold jump (always true when jump_intention is true)
-- should_jump            bool            should the character jump when next frame is entered? used to delay variable jump/hop by 1 frame
-- has_jumped_this_frame  bool            has the character started a jump/hop this frame?
-- has_interrupted_jump   bool            has the character already interrupted his jump once?
-- current_sprite         string          current sprite key in the spr_data
function player_char:_init()
  self.spr_data = pc_data.sonic_sprite_data
  self.debug_move_max_speed = pc_data.debug_move_max_speed
  self.debug_move_accel = pc_data.debug_move_accel
  self.debug_move_decel = pc_data.debug_move_decel

  self:_setup()
end

function player_char:_setup()
  self.control_mode = control_modes.human
--#if cheat
  self.motion_mode = motion_modes.platformer
--#endif
  self.motion_state = motion_states.grounded
  self.horizontal_dir = horizontal_dirs.right

  self.position = vector.zero()
  self.ground_speed = 0.
  self.velocity = vector.zero()
  self.debug_velocity = vector.zero()
  self.slope_angle = 0

  self.move_intention = vector.zero()
  self.jump_intention = false
  self.hold_jump_intention = false
  self.should_jump = false
  self.has_jumped_this_frame = false
  self.has_interrupted_jump = false

  self.current_sprite = "idle"
end

-- spawn character at given position, and escape from ground / enter airborne state if needed
function player_char:spawn_at(position)
  self:_setup()
  self:warp_to(position)
end

-- spawn character at given bottom position, with same post-process as spawn_at
function player_char:spawn_bottom_at(bottom_position)
  self:spawn_at(bottom_position - vector(0, pc_data.center_height_standing))
end

-- warp character to specific position, and update motion state
--  use this when you don't want to reset the character state as spawn_at does
function player_char:warp_to(position)
  self.position = position

  -- character is initialized grounded, but let him fall if he is spawned in the air
  local is_grounded = self:_check_escape_from_ground()
  -- always enter new state depending on whether ground is detected,
  --  forcing state vars reset even if we haven't changed state
  local new_state = is_grounded and motion_states.grounded or motion_states.airborne
  self:_enter_motion_state(new_state)
end

-- same as warp_to, but with bottom position
function player_char:warp_bottom_to(bottom_position)
  self:warp_to(bottom_position - vector(0, pc_data.center_height_standing))
end

-- move the player character so that the bottom center is at the given position
function player_char:get_bottom_center()
  return self.position + vector(0, pc_data.center_height_standing)
end

-- move the player character so that the bottom center is at the given position
function player_char:set_bottom_center(bottom_center_position)
  self.position = bottom_center_position - vector(0, pc_data.center_height_standing)
end

-- move the player character from delta_vector in px
function player_char:move_by(delta_vector)
  self.position = self.position + delta_vector
end

function player_char:update()
  self:_handle_input()
  self:_update_motion()
end

-- update intention based on current input
function player_char:_handle_input()
  if self.control_mode == control_modes.human then
    -- move
    local player_move_intention = vector.zero()

    if input:is_down(button_ids.left) then
      player_move_intention:add_inplace(vector(-1, 0))
    elseif input:is_down(button_ids.right) then
      player_move_intention:add_inplace(vector(1, 0))
    end

    if input:is_down(button_ids.up) then
      player_move_intention:add_inplace(vector(0, -1))
    elseif input:is_down(button_ids.down) then
      player_move_intention:add_inplace(vector(0, 1))
    end

    self.move_intention = player_move_intention

    -- jump
    local is_jump_input_down = input:is_down(button_ids.o)  -- convenient var for optional pre-check
    -- set jump intention each frame, don't set it to true for later consumption to avoid sticky input
    --  without needing a reset later during update
    self.jump_intention = is_jump_input_down and input:is_just_pressed(button_ids.o)
    self.hold_jump_intention = is_jump_input_down

--#if cheat
    if input:is_just_pressed(button_ids.x) then
      self:_toggle_debug_motion()
    end
--#endif
  end
end

--#if cheat
function player_char:_toggle_debug_motion()
  if self.motion_mode == motion_modes.debug then
    -- respawn character at current position. this will in particular:
    --   - set the motion mode back to platformer
    --   - detect ground and update the motion state correctly
    self:spawn_at(self.position)
  else  -- self.motion_mode == motion_modes.platformer
    self.motion_mode = motion_modes.debug
    self.debug_velocity = vector.zero()
  end
end
--#endif

-- update player position
function player_char:_update_motion()
--#if cheat
  if self.motion_mode == motion_modes.debug then
    self:_update_debug()
    return
  end
  -- else: self.motion_mode == motion_modes.platformer
--#endif

  self:_update_platformer_motion()
end

-- return (signed_distance, slope_angle) where:
--  - signed_distance is the signed distance to the highest ground when character center is at center_position,
--   either negative when (in abs, penetration height)
--   or positive (actual distance to ground), always abs clamped to tile_size+1
--  - slope_angle is the slope angle of the highest ground. in case of tie,
--   the character's velocity x sign, then his horizontal direction determines which ground is chosen
-- if both sensors have different signed distances,
--  the lowest signed distance is returned (to escape completely or to have just 1 sensor snapping to the ground)
function player_char:_compute_ground_sensors_signed_distance(center_position)

  -- initialize with negative value to return if the character is not intersecting ground
  local min_signed_distance = 1 / 0  -- max (32768 in pico-8, but never enter it manually as it would be negative)
  local highest_ground_slope_angle = nil

  -- check both ground sensors for ground. if any finds ground, return true
  for i in all({horizontal_dirs.left, horizontal_dirs.right}) do

    -- check that ground sensor #i is on top of or below the mask column
    local sensor_position = self:_get_ground_sensor_position_from(center_position, i)
    local query_info = self:_compute_signed_distance_to_closest_ground(sensor_position)
    local signed_distance, slope_angle = query_info.signed_distance, query_info.slope_angle

    -- apply ground priority rule: highest ground, then velocity x sign breaks tie, then horizontal direction breaks tie

    -- store the biggest penetration height among sensors
    if signed_distance < min_signed_distance then
      -- this ground is higher than the previous one, store new height and slope angle
      min_signed_distance = signed_distance
      highest_ground_slope_angle = slope_angle
    elseif signed_distance == min_signed_distance and self:_get_prioritized_dir() == i then
      -- this ground has the same height as the previous one, but character orientation
      --  makes him stand on that one rather than the previous one, so we use its slope
      highest_ground_slope_angle = slope_angle
    end

  end

  return collision.ground_query_info(min_signed_distance, highest_ground_slope_angle)

end

function player_char:_get_prioritized_dir()
  if self.motion_state == motion_states.grounded then
    if self.ground_speed ~= 0 then
      return signed_speed_to_dir(self.ground_speed)
    end
  else
    if self.velocity.x ~= 0 then
      return signed_speed_to_dir(self.velocity.x)
    end
  end
  return self.horizontal_dir
end

-- return the position of the ground sensor in horizontal_dir when the character center is at center_position
-- subpixels are ignored
function player_char:_get_ground_sensor_position_from(center_position, horizontal_dir)

  -- ignore subpixels from center position in x
  local x_floored_center_position = vector(flr(center_position.x), center_position.y)
  local x_floored_bottom_center = x_floored_center_position + vector(0, pc_data.center_height_standing)

  -- using a ground_sensor_extent_x in .5 and flooring +/- this value allows us to get the checked column x (the x corresponds to the left of that column)
  local offset_x = flr(horizontal_dir_signs[horizontal_dir] * pc_data.ground_sensor_extent_x)

  return x_floored_bottom_center + vector(offset_x, 0)
end

-- return (signed_distance, slope_angle) where:
--  - signed distance to closest ground from floored sensor_position,
--     either negative when (in abs, penetration height, clamped to max_ground_escape_height+1)
--      or positive (actual distance to ground, clamped to max_ground_snap_height+1)
--     if no closest ground is detected, this defaults to max_ground_snap_height+1 (character in the air)
--  - slope_angle is the slope angle of the detected ground (whether character is touching it, above or below)
--  the closest ground is detected in the range [-max_ground_escape_height-1, max_ground_snap_height+1]
--   around the sensor_position.y, so it's easy to know if the character can step up/down,
--   and so that it's meaningful to check for ceiling obstacles after the character did his best to step
--  the test should be tile-insensitive so it is possible to detect step up/down in vertical-neighboring tiles
function player_char:_compute_signed_distance_to_closest_ground(sensor_position)

  assert(flr(sensor_position.x) == sensor_position.x, "player_char:_compute_signed_distance_to_closest_ground: sensor_position.x must be floored")
  initial_y = flr(sensor_position.y)

  -- check the presence of a collider pixel from top to bottom, from max step up - 1 to min step up (we don't go until + 1
  --  because if we found nothing until min step down, signed distance will be max step down + 1 anyway)
  local query_info = collision.ground_query_info(pc_data.max_ground_snap_height + 1, nil)
  for offset_y = -pc_data.max_ground_escape_height - 1, pc_data.max_ground_snap_height do
    local does_collide, slope_angle = world.get_pixel_collision_info(sensor_position.x, initial_y + offset_y)
    if does_collide then
      -- signed_distance is just the current offset, minus the initial subpixel fraction that we ignored for the pixel test iteration
      local fraction_y = sensor_position.y - initial_y
      query_info = collision.ground_query_info(offset_y - fraction_y, slope_angle)  -- slope_angle may still be nil if we are inside ground
      break
    else
      -- optimization: use extra info from is_collision_pixel to skip pixels that we know are empty already thx to the column system
    end
  end

  -- return signed distance and slope angle (the latter may be nil)
  return query_info

end

-- verifies if character is inside ground, and push him upward outside if inside but not too deep inside
-- if ground is detected and the character can escape, update the slope angle with the angle of the new ground
-- if the character cannot escape, we don't need to reset the slope angle to arbitrary 0, as this method is only called
--  when spawning or from an airborne motion, where slope angle is already 0
-- return true iff the character was either touching the ground or inside it (even too deep)
function player_char:_check_escape_from_ground()
  local query_info = self:_compute_ground_sensors_signed_distance(self.position)
  local signed_distance_to_closest_ground, next_slope_angle = query_info.signed_distance, query_info.slope_angle
  local should_escape = signed_distance_to_closest_ground < 0 and abs(signed_distance_to_closest_ground) <= pc_data.max_ground_escape_height
  if should_escape then
    self.position.y = self.position.y + signed_distance_to_closest_ground
  end
  if signed_distance_to_closest_ground == 0 or should_escape then
    -- character was either touching ground, or inside it and escaped
    --  so update his slope angle
    self.slope_angle = next_slope_angle
  end
  return signed_distance_to_closest_ground <= 0
end

-- enter motion state, reset state vars appropriately
function player_char:_enter_motion_state(next_motion_state)
  self.motion_state = next_motion_state
  if next_motion_state == motion_states.airborne then
    -- we have just left the ground, enter airborne state
    --  and since ground speed is now unused, reset it for clarity
    self.ground_speed = 0
    self.should_jump = false
    self.current_sprite = "spin"
  elseif next_motion_state == motion_states.grounded then
    -- we have just reached the ground (and possibly escaped),
    --  reset values airborne vars
    self.velocity.y = 0  -- no velocity retain yet on y
    self.has_jumped_this_frame = false  -- optional since consumed immediately in _update_platformer_motion_airborne
    self.has_interrupted_jump = false
    self.current_sprite = "idle"
  end
end

-- update velocity, position and state based on current motion state
function player_char:_update_platformer_motion()
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
function player_char:_update_platformer_motion_grounded()
  self:_update_ground_speed()

  local ground_motion_result = self:_compute_ground_motion_result()

  -- reset ground speed if blocked
  if ground_motion_result.is_blocked then
    self.ground_speed = 0
  end

  -- update velocity based on new ground speed and old slope angle (positive clockwise and top-left origin, so +cos, -sin)
  -- we must use the old slope because if character is leaving ground (falling)
  --  this frame, new slope angle will be nil
  self.velocity = self.ground_speed * vector(cos(self.slope_angle), -sin(self.slope_angle))

  -- we can now update position and slope
  self.position = ground_motion_result.position
  self.slope_angle = ground_motion_result.slope_angle

  -- todo: reset jump intention on fall... we don't want character to cancel a natural fall by releasing jump button
  -- (does not happen because of negative jump speed interrupt threshold, but could happen
  --  once inertia is added by running off an ascending cliff)
  if ground_motion_result.is_falling then
    self:_enter_motion_state(motion_states.airborne)
  else
    -- only allow jump preparation for next frame if not already falling
    self:_check_jump_intention()
  end

  log("self.position: "..self.position, "trace")
  log("self.position.x (hex): "..tostr(self.position.x, true), "trace")
  log("self.position.y (hex): "..tostr(self.position.y, true), "trace")
  log("self.velocity: "..self.velocity, "trace")
  log("self.velocity.x (hex): "..tostr(self.velocity.x, true), "trace")
  log("self.velocity.y (hex): "..tostr(self.velocity.y, true), "trace")
  log("self.ground_speed: "..self.ground_speed, "trace")
end

-- update ground speed
function player_char:_update_ground_speed()
  -- we need to update ground speed by intention first so accel/decel is handled correctly
  --  otherwise, when starting at speed 0 on an ascending slope, gravity changes speed to < 0
  --  and a right move intention would be handled as a decel, which is fast enough to climb up
  --  even the highest slopes
  -- FIXME: but that broke low slopes since we apply friction for nothing,
  --  then the slope factor...
  -- Instead, we need to synthetize by applying the slope factor in the background,
  --  then the move intention but not based on the intermediate speed but the old speed (or better, the horizontal dir)
  self:_update_ground_speed_by_intention()
  self:_update_ground_speed_by_slope()
  self:_clamp_ground_speed()
end

-- update ground speed based on current slope
function player_char:_update_ground_speed_by_slope()
  if self.slope_angle ~= 0 then
    self.ground_speed = self.ground_speed - pc_data.slope_accel_factor_frame2 * sin(self.slope_angle)
  end
end

-- update ground speed based on current move intention
function player_char:_update_ground_speed_by_intention()
  if self.move_intention.x ~= 0 then

    if self.ground_speed == 0 or sgn(self.ground_speed) == sgn(self.move_intention.x) then
      -- accelerate
      self.ground_speed = self.ground_speed + self.move_intention.x * pc_data.ground_accel_frame2
    else
      -- decelerate
      self.ground_speed = self.ground_speed + self.move_intention.x * pc_data.ground_decel_frame2
      -- if speed must switch sign this frame, clamp it by ground accel in absolute value to prevent exploit of
      --  moving back 1 frame then forward to gain an initial speed boost (mentioned in Sonic Physics Guide as a bug)
      local has_changed_sign = self.ground_speed ~= 0 and sgn(self.ground_speed) == sgn(self.move_intention.x)
      if has_changed_sign and abs(self.ground_speed) > pc_data.ground_accel_frame2 then
        self.ground_speed = sgn(self.ground_speed) * pc_data.ground_accel_frame2
      end
    end

    if self.ground_speed ~= 0 then
      -- always update direction when player tries to move and the character is moving after update
      -- this is useful even when move intention x has same sign as ground speed,
      -- as the character may be running backward after failing to run a steep slope up
      self.horizontal_dir = signed_speed_to_dir(self.ground_speed)
    end

  elseif self.ground_speed ~= 0 then
    -- friction
    self.ground_speed = sgn(self.ground_speed) * max(0, abs(self.ground_speed) - pc_data.ground_friction_frame2)
  end
end

-- clamp ground speed to max
function player_char:_clamp_ground_speed()
  if abs(self.ground_speed) > pc_data.max_ground_speed then
    self.ground_speed = sgn(self.ground_speed) * pc_data.max_ground_speed
  end
end

-- return {next_position: vector, is_blocked: bool, is_falling: bool} where
--  - next_position is the position of the character next frame considering his current ground speed
--  - is_blocked is true iff the character encounters a wall during this motion
--  - is_falling is true iff the character leaves the ground just by running during this motion
function player_char:_compute_ground_motion_result()
  -- if character is not moving, he is not blocked nor falling (we assume the environment is static)
  if self.ground_speed == 0 then
    return collision.ground_motion_result(
      self.position,
      self.slope_angle,
      false,
      false
    )
  end

  local horizontal_dir = signed_speed_to_dir(self.ground_speed)

  -- initialise result with floored x (we will reinject subpixels if character didn't touch a wall)
  -- note that left and right are not completely symmetrical since floor is asymmetrical
  local floored_x = flr(self.position.x)
  local motion_result = collision.ground_motion_result(
    vector(floored_x, self.position.y),
    self.slope_angle,
    false,
    false
  )

  -- only full pixels matter for collisions, but subpixels may sum up to a full pixel
  --  so first estimate how many full pixel columns the character may actually explore this frame
  local signed_distance_x = self.ground_speed * cos(self.slope_angle)
  local max_column_distance = player_char._compute_max_pixel_distance(self.position.x, signed_distance_x)

  -- iterate pixel by pixel on the x direction until max possible distance is reached
  --  only stopping if the character is blocked by a wall (not if falling, since we want
  --  him to continue moving in the air as far as possible; in edge cases, he may even
  --  touch the ground again some pixels farther)
  local column_distance_before_step = 0
  while column_distance_before_step < max_column_distance and not motion_result.is_blocked do
    self:_next_ground_step(horizontal_dir, motion_result)
    column_distance_before_step = column_distance_before_step + 1
  end

  -- check if we need to add or cut subpixels
  if not motion_result.is_blocked then
    -- local max_distance_x = abs(signed_distance_x)
    -- local distance_to_floored_x = abs(motion_result.position.x - floored_x)
    -- since character was not blocked, we know that we have reached a column distance of max_column_distance
    -- local are_subpixels_left = max_distance_x > distance_to_floored_x
    -- since subpixels are always counted to the right, the subpixel test below is asymmetrical
    --   but this is correct, we will simply move backward a bit when moving left
    local are_subpixels_left = self.position.x + signed_distance_x > motion_result.position.x

    if are_subpixels_left then
      -- character has not been blocked and has some subpixels left to go
      -- unlike Classic Sonic, and *only* when moving right, we decide to check if those
      --   subpixels would leak to hitting a wall on the right, and cut them if so,
      --   blocking the character on the spot (we just reuse the result of the extra step,
      --   since is_falling doesn't change if is_blocked is true)
      -- when moving left, the subpixels are a small "backward" motion to the right and should
      --  never hit a wall back
      local is_blocked_by_extra_step = false
      if signed_distance_x > 0 then
        local extra_step_motion_result = motion_result:copy()
        self:_next_ground_step(horizontal_dir, extra_step_motion_result)
        if extra_step_motion_result.is_blocked then
          motion_result = extra_step_motion_result
          is_blocked_by_extra_step = true
        end
      end

      -- unless moving right and hitting a wall due to subpixels, apply the remaining subpixels
      --   as they cannot affect collision anymore. when moving left, they go a little backward
      if not is_blocked_by_extra_step then
        -- character has not touched a wall at all, so add the remaining subpixels
        --   (it's simpler to just recompute the full motion in x; don't touch y tough,
        --   as it depends on the shape of the ground)
        -- do not apply other changes (like slope) since technically we have not reached
        --   the next tile yet, only advanced of some subpixels
        -- note that this calculation equivalent to adding to ref_motion_result.position[coord]
        --   sign(signed_distance_x) * (max_distance_x - distance_to_floored_x)
        motion_result.position.x = self.position.x + signed_distance_x
      end
    end
  end

  return motion_result
end

-- return the number of new pixel columns explored when moving from initial_position_coord (x or y)
--  over velocity_coord (x or y) * 1 frame. consider full pixel motion starting at floored coord,
--  even when moving in the negative direction
-- this is either flr(velocity_coord)
--  or flr(velocity_coord) + 1 (if subpixels from initial position coord and speed sum up to 1.0 or more)
-- note that for negative motion, we must go a bit beyond the next integer to count a full pixel motion,
--  and that is intended
function player_char._compute_max_pixel_distance(initial_position_coord, velocity_coord)
  return abs(flr(initial_position_coord + velocity_coord) - flr(initial_position_coord))
end

-- update ref_motion_result: collision.ground_motion_result for a character trying to move
--  by 1 pixel step in horizontal_dir, taking obstacles into account
-- if character is blocked, it doesn't update the position and flag is_blocked
-- if character is falling, it updates the position and flag is_falling
-- ground_motion_result.position.x should be floored for these steps
--  (some functions assert when giving subpixel coordinates)
function player_char:_next_ground_step(horizontal_dir, ref_motion_result)
  -- compute candidate position on next step. only flat slopes supported
  local step_vec = horizontal_dir_vectors[horizontal_dir]
  local next_position_candidate = ref_motion_result.position + step_vec

  -- check if next position is inside/above ground
  local query_info = self:_compute_ground_sensors_signed_distance(next_position_candidate)
  local signed_distance_to_closest_ground, next_slope_angle = query_info.signed_distance, query_info.slope_angle
  if signed_distance_to_closest_ground < 0 then
    -- position is inside ground, check if we can step up during this step
    local penetration_height = - signed_distance_to_closest_ground
    if penetration_height <= pc_data.max_ground_escape_height then
      -- step up
      next_position_candidate.y = next_position_candidate.y - penetration_height
      -- if we left the ground during a previous step, cancel that (step up land, very rare)
      ref_motion_result.is_falling = false
    else
      -- step blocked: step up is too high, character is blocked
      -- if character left the ground during a previous step, let it this way;
      --  character will simply hit the wall, then fall
      ref_motion_result.is_blocked = true
    end
  elseif signed_distance_to_closest_ground > 0 then
    -- position is above ground, check if we can step down during this step
    if signed_distance_to_closest_ground <= pc_data.max_ground_snap_height then
      -- step down
      next_position_candidate.y = next_position_candidate.y + signed_distance_to_closest_ground
      -- if character left the ground during a previous step, cancel that (step down land, very rare)
      ref_motion_result.is_falling = false
    else
      -- step fall: step down is too low, character will fall
      -- in some rare instances, character may find ground again farther, so don't stop the outside loop yet
      -- caution: we are not updating y at all, which means the character starts
      --  "walking horizontally in the air". in sonic games, we would expect
      --  momentum to take over and send the character upward/downward, preserving
      --  velocity y from last frame
      -- so when adding momentum, consider reusing the last delta y (e.g. signed_distance_to_closest_ground)
      --  and applying it this frame
      ref_motion_result.is_falling = true
    end
  else
    -- step flat
    -- if character left the ground during a previous step, cancel that (very rare)
    ref_motion_result.is_falling = false
  end

  -- character is not blocked by a steep step up/wall, but we need to check if it is
  --  blocked by a ceiling too low; in the extreme case, a diagonal tile pattern
  --  ->X
  --   X
  if not ref_motion_result.is_blocked then
    ref_motion_result.is_blocked = self:_is_blocked_by_ceiling_at(next_position_candidate)

    -- only advance if character is still not blocked (else, preserve previous position,
    --  which should be floored)
    -- this only works because the wall sensors are 1px farther from the character center
    --  than the ground sensors; if there were even farther, we'd even need to
    --  move the position backward by hypothetical wall_sensor_extent_x - ground_sensor_extent_x - 1
    --  when ref_motion_result.is_blocked (and adapt y)
    if not ref_motion_result.is_blocked then
      ref_motion_result.position = next_position_candidate
      if ref_motion_result.is_falling then
        ref_motion_result.slope_angle = nil
      else
        ref_motion_result.slope_angle = next_slope_angle
      end
    end
  end
end

-- return true iff the character cannot stand in his full height (based on ground_sensor_extent_x)
--  at position because of the ceiling (or a full tile if standing at the top of a tile)
function player_char:_is_blocked_by_ceiling_at(center_position)

  -- check ceiling from both ground sensors. if any finds one, return true
  for i in all({horizontal_dirs.left, horizontal_dirs.right}) do

    -- check if ground sensor #i has ceiling closer than a character's height
    local sensor_position = self:_get_ground_sensor_position_from(center_position, i)
    if player_char._is_column_blocked_by_ceiling_at(sensor_position) then
      return true
    end

  end

  return false
end

-- return true iff there is a ceiling above in the column of sensor_position, in a tile above
--  sensor_position's tile, within a height lower than a character's height
-- note that we return true even if the detected obstacle is lower than one step up's height,
--  because we assume that if the character could step this up, it would have and the passed
--  sensor_position would be the resulting position, so only higher tiles will be considered
--  so the step up itself will be ignored (e.g. when moving from a flat ground to an ascending slope)
function player_char._is_column_blocked_by_ceiling_at(sensor_position)

  assert(flr(sensor_position.x) == sensor_position.x, "player_char:_is_column_blocked_by_ceiling_at: sensor_position.x must be floored")

  -- find the tile where this sensor is located
  local curr_tile_loc = sensor_position:to_location()
  local sensor_location_topleft = curr_tile_loc:to_topleft_position()
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
    curr_tile_loc.j = curr_tile_loc.j - 1
    local current_tile_top = curr_tile_loc:to_topleft_position().y
    local current_tile_bottom = current_tile_top + tile_size

    -- if the bottom of next ceiling to check is already higher than, or equal to
    --  one character height, if cannot block him, so return false
    local height_distance = sensor_position.y - current_tile_bottom
    if height_distance >= pc_data.full_height_standing then
      return false
    end

    local ground_array_height, _ = world._compute_column_height_at(curr_tile_loc, column_index0)
    if ground_array_height ~= nil and ground_array_height > 0 then
      -- with non-rotated tiles, we are sure to hit the ceiling at this point
      --  because ceiling is always at a tile bottom, and we return false
      --  as soon as we go up farther than a character's height
      return true
      -- with ceiling tiles, we will need to check if the ceiling column height
      --  hits the head or not. if it doesn't stop here, return false,
      --  the head is below the ceiling:
      -- local height_distance = sensor_position.y - current_tile_bottom
      -- return height_distance < pc_data.full_height_standing
    end

  end

end

-- if character intends to jump, prepare jump for next frame
-- this extra frame allows us to detect if the player wants a variable jump or a hop
--  depending whether input is hold or not
function player_char:_check_jump_intention()
  if self.jump_intention then
    -- consume intention so puppet control mode (which is sticky) also works
    self.jump_intention = false
    self.should_jump = true
  end
end

-- if character intends to jump, apply jump velocity from current ground
--  and enter the airborne state
-- return true iff jump was applied
function player_char:_check_jump()
  if self.should_jump then
    self.should_jump = false

    -- apply initial jump speed for variable jump
    -- note: if the player is doing a hop, the vertical speed will be reset
    --  to the interrupt speed during the same frame in _update_platformer_motion_airborne
    --  via _check_hold_jump (we don't do it here so we centralize the check and
    --  don't apply gravity during such a frame)
    -- limitation: only support flat ground for now
    self.velocity.y = self.velocity.y - pc_data.initial_var_jump_speed_frame
    self:_enter_motion_state(motion_states.airborne)
    self.has_jumped_this_frame = true
    return true
  end
  return false
end

-- update motion following platformer airborne motion rules
function player_char:_update_platformer_motion_airborne()
  if self.has_jumped_this_frame then
    -- do not apply gravity on first frame of jump, and consume has_jumped_this_frame
    self.has_jumped_this_frame = false
  else
    -- apply gravity to current speed y
    self.velocity.y = self.velocity.y + pc_data.gravity_frame2
  end

  -- check if player is continuing or interrupting jump *after* applying gravity
  -- this means gravity will *not* be applied during the hop/interrupt jump frame
  self:_check_hold_jump()

  -- apply x acceleration via intention (if not 0)
  self.velocity.x = self.velocity.x + self.move_intention.x * pc_data.air_accel_x_frame2

  -- apply air motion

  local air_motion_result = self:_compute_air_motion_result()

  self.position = air_motion_result.position

  if air_motion_result.is_blocked_by_wall then
    self.velocity.x = 0
  end

  if air_motion_result.is_blocked_by_ceiling then
    self.velocity.y = 0
  end

  if air_motion_result.is_landing then
    self.slope_angle = air_motion_result.slope_angle
    self:_enter_motion_state(motion_states.grounded)
  end

  log("self.position: "..self.position, "trace")
  log("self.velocity: "..self.velocity, "trace")
end

-- check if character wants to interrupt jump by not holding anymore,
--  and set vertical speed to interrupt speed if so
function player_char:_check_hold_jump()
  if not self.has_interrupted_jump and not self.hold_jump_intention then
    -- character has not interrupted jump yet and wants to
    -- flag jump as interrupted even if it's too late, so we don't enter this block anymore
    self.has_interrupted_jump = true

    -- character tries to interrupt jump, check if's not too late
    local signed_jump_interrupt_speed_frame = -pc_data.jump_interrupt_speed_frame
    if self.velocity.y < signed_jump_interrupt_speed_frame then
      log("interrupt jump "..self.velocity.y.." -> "..signed_jump_interrupt_speed_frame, "trace")
      self.velocity.y = signed_jump_interrupt_speed_frame
    end
  end
end

-- return {next_position: vector, is_blocked_by_ceiling: bool, is_blocked_by_wall: bool, is_landing: bool} where
--  - next_position is the position of the character next frame considering his current (air) velocity
--  - is_blocked_by_ceiling is true iff the character encounters a ceiling during this motion
--  - is_blocked_by_wall is true iff the character encounters a wall during this motion
--  - is_landing is true iff the character touches a ground from above during this motion
function player_char:_compute_air_motion_result()
  -- if character is not moving, he is not blocked nor landing (we assume the environment is static)
  if self.velocity == vector.zero() then
    return collision.air_motion_result(
      self.position,
      false,
      false,
      false,
      nil
    )
  end

  -- initialize air motion result (do not floor coordinates, _advance_in_air_along will do it)
  local motion_result = collision.air_motion_result(
    vector(self.position.x, self.position.y),
    false,
    false,
    false,
    nil
  )

  -- from here, unlike ground motion, there are 3 ways to iterate:
  -- a. describe a Bresenham's line, stepping on x and y, for the best precision
  -- b. step on x until you reach the max distance x, then step on y (may hit wall you wouldn't have with a. or c.)
  -- c. step on y until you reach the max distance y, then step on x (may hit ceiling you wouldn't have with a. or b.)

  -- we focus on landing/ceiling first, and prefer simplicity to precision as long as motion seems ok,
  --  so we choose c.
  self:_advance_in_air_along(motion_result, self.velocity, "y")
  log("=> "..motion_result, "trace")
  self:_advance_in_air_along(motion_result, self.velocity, "x")
  log("=> "..motion_result, "trace")

  return motion_result
end

-- TODO: factorize with _compute_ground_motion_result
-- modifies ref_motion_result in-place, setting it to the result of an air motion from ref_motion_result.position
--  over velocity[coord] px, where coord is "x" or "y"
function player_char:_advance_in_air_along(ref_motion_result, velocity, coord)
  log("_advance_in_air_along: "..joinstr(", ", ref_motion_result, velocity, coord), "trace")

  if velocity[coord] == 0 then return end

  -- only full pixels matter for collisions, but subpixels may sum up to a full pixel
  --  so first estimate how many full pixel columns the character may actually explore this frame
  local initial_position_coord = ref_motion_result.position[coord]
  local max_pixel_distance = player_char._compute_max_pixel_distance(initial_position_coord, velocity[coord])

  -- floor coordinate to simplify step by step pixel detection (mostly useful along x to avoid
  --  flooring every time we query column heights)
  -- since initial_position_coord is storing the original position with subpixels, we are losing information
  ref_motion_result.position[coord] = flr(ref_motion_result.position[coord])

  -- iterate pixel by pixel on the x direction until max possible distance is reached
  --  only stopping if the character is blocked by a wall (not if falling, since we want
  --  him to continue moving in the air as far as possible; in edge cases, he may even
  --  touch the ground again some pixels farther)
  local direction
  if coord == "x" then
    direction = directions.right
  else
    direction = directions.down
  end
  if velocity[coord] < 0 then
    direction = oppose_direction(direction)
  end

  local pixel_distance_before_step = 0
  while pixel_distance_before_step < max_pixel_distance and not ref_motion_result:is_blocked_along(direction) do
    self:_next_air_step(direction, ref_motion_result)
    log("  => "..ref_motion_result, "trace")
    pixel_distance_before_step = pixel_distance_before_step + 1
  end

  -- check if we need to add or cut subpixels
  if not ref_motion_result:is_blocked_along(direction) then
    -- since subpixels are always counted to the right, the subpixel test below is asymmetrical
    --   but this is correct, we will simply move backward a bit when moving left
    local are_subpixels_left = initial_position_coord + velocity[coord] > ref_motion_result.position[coord]
    -- local are_subpixels_left = initial_position_coord + max_pixel_distance > ref_motion_result.position[coord]
    if are_subpixels_left then
      -- character has not been blocked and has some subpixels left to go
      --  *only* when moving in the positive sense (right/up),
      --  as a way to clean the subpixels unlike classic sonic,
      --  we check if character is theoretically colliding a wall with those subpixels
      --  (we need an extra step to "ceil" the subpixels)
      -- when moving in the negative sense, the subpixels are a small "backward" motion
      --  to the positive sense and should
      --  never hit a wall back
      local is_blocked_by_extra_step = false
      if velocity[coord] > 0 then
        local extra_step_motion_result = ref_motion_result:copy()
        self:_next_air_step(direction, extra_step_motion_result)
        log("  => "..ref_motion_result, "trace")
        if extra_step_motion_result:is_blocked_along(direction) then
          -- character has just reached a wall, plus a few subpixels
          -- unlike classic sonic, we decide to cut the subpixels and block the character
          --  on the spot (we just reuse the result of the extra step, since is_falling doesn't change if is_blocked is true)
          -- it's very important to keep the reference and assign member values instead
          ref_motion_result:copy_assign(extra_step_motion_result)
          is_blocked_by_extra_step = true
        end
      end

      if not is_blocked_by_extra_step then
        -- character has not touched a wall at all, so add the remaining subpixels
        --  (it's simpler to just recompute the full motion in x; don't touch y tough,
        --  as it depends on the shape of the ground)
        -- do not apply other changes (like slope) since technically we have not reached
        --  the next tile yet, only advanced of some subpixels
        -- note that this calculation equivalent to adding to ref_motion_result.position[coord]
        --  sign(velocity[coord]) * (max_distance - distance_to_floored_coord)
        ref_motion_result.position[coord] = initial_position_coord + velocity[coord]
      end
    end
  end
end

-- update ref_motion_result: collision.air_motion_result for a character trying to move
--  by 1 pixel step in direction in the air, taking obstacles into account
-- if character is blocked by wall, ceiling or landing when moving toward left/right, up or down resp.,
--  it doesn't update the position and the corresponding flag is set
-- air_motion_result.position.x/y should be floored for these steps
function player_char:_next_air_step(direction, ref_motion_result)
  log("  _next_air_step: "..joinstr(", ", direction, ref_motion_result), "trace")

  local step_vec = dir_vectors[direction]
  local next_position_candidate = ref_motion_result.position + step_vec

  log("direction: "..direction, "trace")
  log("step_vec: "..step_vec, "trace")
  log("next_position_candidate: "..next_position_candidate, "trace")

  -- we can only hit walls or the ground when moving left, right or down
  if direction ~= directions.up then
    -- query ground to check for obstacles (we only care about distance, not slope angle)
    -- note that we reuse the ground sensors for air motion, because they are good at finding
    --  collisions around the bottom left/right corners
    local query_info = self:_compute_ground_sensors_signed_distance(next_position_candidate)
    local signed_distance_to_closest_ground, next_slope_angle = query_info.signed_distance, query_info.slope_angle

    log("signed_distance_to_closest_ground: "..signed_distance_to_closest_ground, "trace")

    -- check if the character has hit a ground or a wall
    if signed_distance_to_closest_ground < 0 then
      -- we do not activate step up during air motion, so any pixel above the character's bottom
      --  is considered a hard obstacle
      -- depending on the direction, we consider we were blocked by either a ceiling or a wall
      if direction == directions.down then
        -- landing: the character has just set foot on ground, flag it and initialize slope angle
        -- note that we only consider the character to touch ground when it is about to enter it
        -- therefore, if he exactly reaches signed_distance_to_closest_ground == 0 this frame,
        --  it is still technically considered in the air
        -- if this step is blocked by landing, there is no extra motion,
        --  but character will enter grounded state
        ref_motion_result.is_landing = true
        ref_motion_result.slope_angle = next_slope_angle
      else
        ref_motion_result.is_blocked_by_wall = true
        log("is blocked by wall", "trace")
      end
    elseif signed_distance_to_closest_ground > 0 then
      -- in the air: the most common case, in general requires nothing to do
      -- in rare cases, the character has landed on a previous step, and we must cancel that now
      ref_motion_result.is_landing = false
      ref_motion_result.slope_angle = nil
    elseif ref_motion_result.is_landing then
      -- if we enter this, direction must be horizontal, so update slope angle with new ground
      ref_motion_result.slope_angle = next_slope_angle
      log("is landing, setting slope angle to "..next_slope_angle, "trace")
    end
  end

  -- we can only hit ceiling when moving left, right or up
  -- note that the ceiling check is necessary during horizontal motion to complement
  --  ground sensors, the edge case being when the bottom of the character matches
  --  the bottom of a collision tile, ground sensors could only detect the tile below
  -- if we have already found a blocker above (only possible for left and right),
  --  then there is no need to check further, though
  if direction ~= directions.down and not ref_motion_result.is_blocked_by_wall then
    local is_blocked_by_ceiling_at_next = self:_is_blocked_by_ceiling_at(next_position_candidate)
    if is_blocked_by_ceiling_at_next then
      if direction == directions.up then
        ref_motion_result.is_blocked_by_ceiling = true
        log("is blocked by ceiling", "trace")
      else
        -- we would be blocked by ceiling on the next position, but since we can't even go there,
        --  we are actually blocked by the wall preventing the horizontal move
        ref_motion_result.is_blocked_by_wall = true
      end
    end
  end

  -- only advance if character is still not blocked (else, preserve previous position,
  --  which should be floored)
  if not ref_motion_result:is_blocked_along(direction) then
    -- this only works because the wall sensors are 1px farther from the character center
    --  than the ground sensors; if there were even farther, we'd even need to
    --  move the position backward by hypothetical wall_sensor_extent_x - ground_sensor_extent_x - 1
    --  when ref_motion_result:is_blocked_along() (and adapt y)
    ref_motion_result.position = next_position_candidate
  end
end

--#if cheat

-- update the velocity and position of the character following debug motion rules
function player_char:_update_debug()
  self:_update_velocity_debug()
  self:move_by(self.debug_velocity * delta_time)
end

function player_char:_update_velocity_debug()
  -- update velocity from input
  -- in debug mode, cardinal speeds are independent and max speed applies to each
  self:_update_velocity_component_debug("x")
  self:_update_velocity_component_debug("y")
end

--#endif

-- update the velocity component for coordinate "x" or "y" with debug motion
-- coord  string  "x" or "y"
function player_char:_update_velocity_component_debug(coord)
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
function player_char:render()
  local flip_x = self.horizontal_dir == horizontal_dirs.left
  self.spr_data[self.current_sprite]:render(self.position, flip_x)
end

return player_char
