require("class")
require("constants")
require("helper")
require("math")
require("sprite")

player_character = new_class()

-- character data

-- motion speed in debug mode, in px/s
local debug_move_max_speed = 60.

-- acceleration speed in debug mode, in px/s^2 (480. to reach max speed of 60. in 0.5s)
local debug_move_accel = 480.

-- deceleration speed in debug mode, in px/s^2 (480. to stop from a speed of 60. in 0.5s)
local debug_move_decel = 480.

-- sprite data
local character_sprite_loc = sprite_id_location(0, 2)
local character_sprite_span = tile_vector(1, 2)        -- vertical sprite
local character_sprite_pivot = vector(4, 12)           -- center of bottom part of the sprite

-- parameters
-- spr_data             sprite_data   sprite data
-- debug_move_max_speed number        move max speed in debug mode
-- debug_move_accel     number        move acceleration in debug mode
-- debug_move_decel     number        move deceleration in debug mode
-- state vars
-- position             vector        current position
-- velocity             vector        current velocity
-- move_intention       vector        current move intention (normalized)
function player_character:_init(position)
 self.spr_data = sprite_data(character_sprite_loc, character_sprite_span, character_sprite_pivot)
 self.debug_move_max_speed = debug_move_max_speed
 self.debug_move_accel = debug_move_accel
 self.debug_move_decel = debug_move_decel

 self.position = position
 self.velocity = vector.zero()
 self.move_intention = vector.zero()
end

function player_character:_tostring()
 return "[player_character at "..self.position.."]"
end

-- update player position
function player_character:update()
  -- update velocity from input (in debug mode, cardinal speeds are independent and max speed applies to each)
  self:update_velocity_component("x")
  self:update_velocity_component("y")

  -- move
  self:move(self.velocity * delta_time)
end

-- update the velocity component for coordinate "x" or "y"
-- coord  string  "x" or "y"
function player_character:update_velocity_component(coord)
  if self.move_intention[coord] ~= 0 then
    -- some input => accelerate (direction may still change or be opposed)
    local clamped_move_intention_comp = mid(-1, self.move_intention[coord], 1)
    self.velocity[coord] += self.debug_move_accel * delta_time * clamped_move_intention_comp
    self.velocity[coord] = mid(-self.debug_move_max_speed, self.velocity[coord], self.debug_move_max_speed)
  else
    -- no input => decelerate
    if self.velocity[coord] ~= 0 then
      self.velocity[coord] = sgn(self.velocity[coord]) * max(abs(self.velocity[coord]) - self.debug_move_decel * delta_time, 0)
    end
  end
end

-- render the player character sprite at its current position
function player_character:render()
 self.spr_data:render(self.position)
end

-- move the player from delta_vector in px
function player_character:move(delta_vector)
  self.position += delta_vector
end
