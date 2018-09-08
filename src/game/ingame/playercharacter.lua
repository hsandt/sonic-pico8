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
-- debug_move_max_speed float         move max speed in debug mode
-- debug_move_accel     float         move acceleration in debug mode
-- debug_move_decel     float         move deceleration in debug mode
-- state vars
-- control_mode         control_modes control mode: human (default) or ai
-- motion_mode          motion_modes  motion mode: platformer (under gravity) or debug (fly around)
-- motion_state         motion_states motion state (platformer mode only)
-- position             vector        current position (character center "between" pixels)
-- debug_velocity       vector        current velocity in debug mode
-- speed_y_per_frame    float         current speed along y axis (px/frame)
-- move_intention       vector        current move intention (normalized)
function player_character:_init(position)
  self.spr_data = sprite_data(playercharacter_data.character_sprite_loc, playercharacter_data.character_sprite_span, playercharacter_data.character_sprite_pivot)
  self.debug_move_max_speed = playercharacter_data.debug_move_max_speed
  self.debug_move_accel = playercharacter_data.debug_move_accel
  self.debug_move_decel = playercharacter_data.debug_move_decel

  self.control_mode = control_modes.human
  self.motion_mode = motion_modes.platformer
  self.motion_state = motion_states.grounded

  self.position = position
  self.debug_velocity = vector.zero()
  self.speed_y_per_frame = 0.

  self.move_intention = vector.zero()
end

--#if log
function player_character:_tostring()
 return "[player_character at "..self.position.."]"
end
--#endif

-- update player position
function player_character:update()
  if self.motion_mode == motion_modes.platformer then
    self:_update_platformer()
  else  -- self.motion_mode == motion_modes.debug
    self:_update_debug()
  end
end

-- update the velocity and position of the character following platformer motion rules
function player_character:_update_platformer()
  -- check if there is some ground under the character
  local is_ground_sensed = self:_intersects_with_ground()
  self:_update_platformer_motion_state(is_ground_sensed)
  self:_update_platformer_motion()
end

-- return penetration height (>= 0) of character inside ground, or -1 if not intersecting ground
--  if both sensors have different penetration heights, the biggest is returned for full escape
function player_character:_compute_ground_penetration_height()

  -- initialize with negative value to return if the character is not intersecting ground
  local max_penetration_height = -1

  -- check both ground sensors for ground. if any finds ground, return true
  for i in all({horizontal_directions.left, horizontal_directions.right}) do

    -- find the tile where this ground sensor is located
    local sensor_position = self:_get_ground_sensor_position(i)
    local sensor_location = sensor_position:to_location()

    -- get column on the collision mask that the ground sensor should check (ground sensor extent x
    --  should be in 0.5 and the 0.5->1 rounding should apply automatically due to flooring)
    -- note that this is slightly suboptimal as we won't use column_index0 at all if _compute_column_height_at returns early

    local sensor_location_topleft = sensor_location:to_topleft_position()
    local sensor_relative_x = sensor_position.x - sensor_location_topleft.x
    local column_index0 = flr(sensor_relative_x)  -- from 0 to tile_size - 1
    local ground_column_height = self:_compute_column_height_at(sensor_location, column_index0)

    if ground_column_height > 0 then

      -- compute relative height of sensor from tile bottom (y axis is downward)
      local sensor_location_bottom = sensor_location_topleft.y + tile_size
      local sensor_height = sensor_location_bottom - sensor_position.y
      assert(sensor_height > 0, "sensor_height is not positive, yet it was computed using sensor_position:to_location() which should always select a tile where the sensor is strictly above the bottom")

      -- check that ground sensor #i is on top of or below the mask column
      local penetration_height = ground_column_height - sensor_height

      if penetration_height >= 0 then
        -- if the column is full (reaches the top of the tile), we must check if there are any tiles
        --  stacked on top of this one, in which case the penetration height will be incremented by everything above
        if ground_column_height == tile_size then
          penetration_height = penetration_height + self:_compute_stacked_column_height_above(sensor_location, column_index0)
        end

        -- store the biggest penetration height among sensors
        if penetration_height > max_penetration_height then
          max_penetration_height = penetration_height
        end
      end

    end

  end

  return max_penetration_height

end

-- return the sum of column heights of colliding tiles starting from the tile
--  just above the passed bottom_tile_location, all along the passed column_index0, up to the first tile
--  that is either outside the map or has not a full column (column height < tile size).
-- this method is important to compute the penetration height/escape distance to escape from multiple stacked tiles at once
function player_character:_compute_stacked_column_height_above(bottom_tile_location, column_index0)

  local stacked_column_height = 0
  local current_tile_location = bottom_tile_location:copy()

  while true do

    -- move 1 tile up from the start
    current_tile_location.j = current_tile_location.j - 1

    local ground_array_height = self:_compute_column_height_at(current_tile_location, column_index0)

    -- stop if no colliding tile or height is 0 just on the column
    if ground_array_height == 0 then
      break
    end

    stacked_column_height = stacked_column_height + ground_array_height

    -- stop if this tile has not a full column
    if ground_array_height < tile_size then
      break
    end

  end

  return stacked_column_height

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
      assert(collision_mask_id_location, "sprite_id_to_collision_mask_id_locations does not contain entry for sprite id: "..tostr(current_tile_id)..", yet it has the collision flag set")

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

-- return true iff there is ground immediately below character's feet
--  (including if the feet are inside the ground)
function player_character:_intersects_with_ground()
  return self:_compute_ground_penetration_height() >= 0
end

-- verifies if character is inside ground, and push him outside if inside but not too deep inside
-- currently, it only pushes the character upward
function player_character:_check_escape_from_ground()
  local penetration_height = self:_compute_ground_penetration_height()
  if penetration_height >= 0 and penetration_height <= playercharacter_data.max_ground_escape_height then
    self:move(vector(0, -penetration_height))
  end
end

function player_character:_get_ground_sensor_position(horizontal_dir)

  if horizontal_dir == horizontal_directions.left then
    return self:get_bottom_center() - vector(playercharacter_data.ground_sensor_extent_x, 0)
  else
    return self:get_bottom_center() + vector(playercharacter_data.ground_sensor_extent_x, 0)
  end
end

-- update motion state based on whether ground was sensed this frame
function player_character:_update_platformer_motion_state(is_ground_sensed)
  if self.motion_state == motion_states.grounded then
    if not is_ground_sensed then
      self.motion_state = motion_states.airborne
    end
  end

  if self.motion_state == motion_states.airborne then
    if is_ground_sensed then
      self.motion_state = motion_states.grounded
      self.speed_y_per_frame = 0
    end
  end
end

-- update velocity and position based on current motion state
function player_character:_update_platformer_motion()
  if self.motion_state == motion_states.grounded then
    self:_update_platformer_motion_grounded()
  end

  if self.motion_state == motion_states.airborne then
    self:_update_platformer_motion_airborne()
  end
end

-- update motion following platformer grounded motion rules
function player_character:_update_platformer_motion_grounded()
end

-- update motion following platformer airborne motion rules
function player_character:_update_platformer_motion_airborne()
  -- apply gravity to current speed y
  self.speed_y_per_frame = self.speed_y_per_frame + playercharacter_data.gravity_per_frame2
  -- apply air motion
  self.position = self.position + vector(0, self.speed_y_per_frame)

  self:_check_escape_from_ground()
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
