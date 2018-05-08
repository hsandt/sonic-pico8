require("class")
require("helper")
require("math")
require("sprite")

player_character = new_class()

-- sprite data
local character_sprite_loc = sprite_id_location(0, 2)
local character_sprite_span = tile_vector(1, 2)

-- position       vector     current position
function player_character:_init(position)
 self.position = position
 self.sprite = sprite_data(character_sprite_loc, character_sprite_span)
end

-- render the player character sprite at its current position
function player_character:render()
 self.sprite:render(self.position)
end
