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
  local is_ground_sensed = self:_sense_ground()
  self:_update_platformer_motion_state(is_ground_sensed)
  self:_update_platformer_motion()
  log("self.motion_state: "..self.motion_state)
  log("self.position: "..self.position)
  log("self.speed_y_per_frame: "..self.speed_y_per_frame)
end

-- return true iff there is ground immediately below character's feet
--  (including if the feet are inside the ground)
function player_character:_sense_ground()

  -- check both ground sensors for ground. if any finds ground, return true
  for i in all({horizontal_directions.left, horizontal_directions.right}) do

    -- find the tile where this ground sensor is located
    local current_ground_sensor_position = self:_get_ground_sensor_position(i)
    local sensor_location = current_ground_sensor_position:to_location()
    local sensed_tile_id = mget(sensor_location.i, sensor_location.j)

    -- check if that tile uses collision
    local current_tile_collision_flag = fget(sensed_tile_id, sprite_flags.collision)

    if current_tile_collision_flag then

      -- get the tile collision mask
      local collision_mask_id_location = collision_data.sprite_id_to_collision_mask_id_locations[sensed_tile_id]
      assert(collision_mask_id_location, "sprite_id_to_collision_mask_id_locations does not contain entry for sprite id: "..tostr(sensed_tile_id)..", yet it has the collision flag set")

      if collision_mask_id_location then
        -- possible optimize: cache collision height array on game start
        local h_array = collision.height_array(collision_mask_id_location, 0)
        local current_ground_sensor_height = sensor_location:to_topleft_position().y + 8 - current_ground_sensor_position.y

        -- get column on the collision mask that the ground sensor should check (ground sensor extent x
        --  should be in 0.5 and the 0.5->1 rounding should apply automatically due to flooring)
        local column_index0 = flr(current_ground_sensor_position.x - sensor_location:to_topleft_position().x)
        local current_ground_array_height = h_array:get_height(column_index0)

        if current_ground_sensor_height <= current_ground_array_height then
          return true
        end

      end

    end

  end

  return false

end

function player_character:_get_ground_sensor_position(horizontal_dir)

  if horizontal_dir == horizontal_directions.left then
    return self.position + vector(- playercharacter_data.ground_sensor_extent_x, playercharacter_data.center_height_standing)
  else
    return self.position + vector(playercharacter_data.ground_sensor_extent_x, playercharacter_data.center_height_standing)
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
