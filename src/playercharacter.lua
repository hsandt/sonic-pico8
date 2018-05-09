require("class")
require("constants")
require("helper")
require("math")
require("sprite")

player_character = new_class()

-- character data

-- motion speed in debug mode, in px/s
local debug_move_speed = 60.

-- sprite data
local character_sprite_loc = sprite_id_location(0, 2)
local character_sprite_span = tile_vector(1, 2)        -- vertical sprite
local character_sprite_pivot = vector(4, 12)           -- center of bottom part of the sprite

-- parameters
-- spr_data         sprite_data   sprite data
-- debug_move_speed number        move speed in debug mode
-- state vars
-- position         vector        current position
-- move_intention   vector        current move intention (normalized)
function player_character:_init(position)
 self.spr_data = sprite_data(character_sprite_loc, character_sprite_span, character_sprite_pivot)
 self.debug_move_speed = debug_move_speed
 self.position = position
 self.move_intention = vector(0, 0)
end

-- update player position
function player_character:update()
 self:move(self.move_intention * self.debug_move_speed * delta_time)
end

-- render the player character sprite at its current position
function player_character:render()
 self.spr_data:render(self.position)
end

-- move the player from delta_vector in px
function player_character:move(delta_vector)
  self.position += delta_vector
end
