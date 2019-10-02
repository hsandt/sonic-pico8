require("engine/test/unittest")
require("engine/core/math")
local tile = require("platformer/tile")
local collision_data = require("data/collision_data")
local height_array = tile.height_array
local tile_data = tile.tile_data

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