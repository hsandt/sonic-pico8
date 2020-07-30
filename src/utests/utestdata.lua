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

check('sprite_id_location(1, 3) should have collision flag set', function (utest_name)
  local sprite_id = sprite_id_location(1, 3):to_sprite_id()
  assert(fget(sprite_id, sprite_flags.collision), "sprite_id_location(0, 4) has collision flag unset", utest_name)
end)

check('sprite_id_location(1, 3) should have collision mask id set to location above, angle atan2(8, 2)', function (utest_name)
  local sprite_id = sprite_id_location(1, 3):to_sprite_id()
  assert(collision_data.tiles_data[sprite_id] == tile_data(sprite_id_location(1, 2), atan2(8, 2)), utest_name)
end)

check('height_array._fill_array on sprite_id_location(2, 3) should fill the array with tile mask data: full', function (utest_name)
  local array = {}
  height_array._fill_array(array, sprite_id_location(2, 3))
  assert(are_same_with_message({8, 8, 8, 8, 8, 8, 8, 8}, array), utest_name)
end)

-- bugfix history: after switching to pink transparency, all my tiles became square blocks
-- warning: it's a proto tile, if you strip it from final build later, test another tile instead
check('= height_array._fill_array on sprite_id_location(1, 7) the array with tile mask data: descending slope 45', function (utest_name)
  local array = {}
  height_array._fill_array(array, sprite_id_location(1, 7))
  assert(are_same_with_message({1, 2, 3, 4, 5, 6, 7, 8}, array), utest_name)
end)

check('sonic_sprite_data_table preserved key "idle"', function (utest_name)
  assert(playercharacter_data.sonic_sprite_data_table["idle"] ~= nil, utest_name)
end)

check('sonic_animated_sprite_data_table preserved key "idle"', function (utest_name)
  assert(playercharacter_data.sonic_animated_sprite_data_table["idle"] ~= nil, utest_name)
end)
