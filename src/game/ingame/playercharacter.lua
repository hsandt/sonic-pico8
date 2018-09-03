require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
require("engine/core/math")
require("engine/render/sprite")
local collision = require("engine/physics/collision")
local collision_data = require("game/data/collision_data")
local playercharacter_data = require("game/data/playercharacter_data")

control_modes = {
  human = 1,      -- player controls character
  ai = 2,         -- ai controls character
  puppet = 3      -- itest script controls character
}

motion_modes = {
  platformer = 1,
  debug = 2
}

player_character = new_class()


-- parameters
-- spr_data             sprite_data   sprite data
-- debug_move_max_speed number        move max speed in debug mode
-- debug_move_accel     number        move acceleration in debug mode
-- debug_move_decel     number        move deceleration in debug mode
-- state vars
-- control_mode         control_modes control mode: human (default) or ai
-- motion_mode          motion_modes  motion mode: platformer (under gravity) or debug (fly around)
-- position             vector        current position (character center "between" pixels)
-- velocity             vector        current velocity
-- move_intention       vector        current move intention (normalized)
function player_character:_init(position)
 self.spr_data = sprite_data(playercharacter_data.character_sprite_loc, playercharacter_data.character_sprite_span, playercharacter_data.character_sprite_pivot)
 self.debug_move_max_speed = playercharacter_data.debug_move_max_speed
 self.debug_move_accel = playercharacter_data.debug_move_accel
 self.debug_move_decel = playercharacter_data.debug_move_decel

 self.control_mode = control_modes.human
 self.motion_mode = motion_modes.platformer

 self.position = position
 self.velocity = vector.zero()
 self.move_intention = vector.zero()
end

--#if log
function player_character:_tostring()
 return "[player_character at "..self.position.."]"
end
--#endif

-- update player position
function player_character:update()
  self:_update_velocity()
  self:move(self.velocity * delta_time)
end

-- update the velocity of the character based on its motion mode and current move intention
function player_character:_update_velocity()
  if self.motion_mode == motion_modes.platformer then
    self:_update_velocity_platformer()
  else  -- self.motion_mode == motion_modes.debug
    self:_update_velocity_debug()
  end
end

function player_character:_update_velocity_platformer()
  -- do something
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
    self.velocity[coord] = self.velocity[coord] + self.debug_move_accel * delta_time * clamped_move_intention_comp
    self.velocity[coord] = mid(-self.debug_move_max_speed, self.velocity[coord], self.debug_move_max_speed)
  else
    -- no input => decelerate
    if self.velocity[coord] ~= 0 then
      self.velocity[coord] = sgn(self.velocity[coord]) * max(abs(self.velocity[coord]) - self.debug_move_decel * delta_time, 0)
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
