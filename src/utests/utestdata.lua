require("engine/test/unittest")
require("engine/core/math")
local tile = require("platformer/tile")
local height_array = tile.height_array
local tile_data = tile.tile_data

-- data to test
local collision_data = require("data/collision_data")
-- this one is not checked although we could verify that sprites are not empty or something
-- but it's useful to check definition sanity (e.g. animation with 0 sprites, in particular
-- after minification if keys are not protected with ["key"] syntax)
local playercharacter_data = require("data/playercharacter_data")

check('sprite_id_location(0, 4) should have collision flag set', function ()
  local sprite_id = sprite_id_location(0, 4):to_sprite_id()
  assert(fget(sprite_id, sprite_flags.collision), "sprite_id_location(0, 4) has collision flag unset")
end)

check('sprite_id_location(0, 4) should have collision mask id set to location below', function ()
  local sprite_id = sprite_id_location(0, 4):to_sprite_id()
  assert(collision_data.tiles_data[sprite_id] == tile_data(sprite_id_location(0, 5), 0))
end)

check('. height_array._fill_array on sprite_id_location(0, 5) should fill the array with tile mask data: full', function ()
  local array = {}
  height_array._fill_array(array, sprite_id_location(0, 5))
  assert(are_same_with_message({8, 8, 8, 8, 8, 8, 8, 8}, array))
end)

-- bugfix history: after switching to pink transparency, all my tiles became square blocks
check('= height_array._fill_array on sprite_id_location(0, 5) the array with tile mask data: descending slope 45', function ()
  local array = {}
  height_array._fill_array(array, sprite_id_location(1, 5))
  assert(are_same_with_message({1, 2, 3, 4, 5, 6, 7, 8}, array))
end)

check('sonic_sprite_data_table preserved key "idle"', function ()
  assert(playercharacter_data.sonic_sprite_data_table["idle"] ~= nil)
end)

check('sonic_animated_sprite_data_table preserved key "idle"', function ()
  assert(playercharacter_data.sonic_animated_sprite_data_table["idle"] ~= nil)
end)
