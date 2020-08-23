require("engine/test/p8utest")
local tile_collision_data = require("data/tile_collision_data")

-- data to test
local collision_data = require("data/collision_data")
-- this one is not checked although we could verify that sprites are not empty or something
-- but it's useful to check definition sanity (e.g. animation with 0 sprites, in particular
-- after minification if keys are not protected with ["key"] syntax)
local playercharacter_data = require("data/playercharacter_data")

check('sprite_id_location(8, 0) (loop top-left) should have collision flag set', function (utest_name)
  local sprite_id = sprite_id_location(8, 0):to_sprite_id()
  assert_log(utest_name, fget(sprite_id, sprite_flags.collision), "sprite_id_location(0, 4) has collision flag unset")
end)

check('sprite_id_location(8, 0) (loop top-left) should have collision arrays of loop top-left, angle atan2(-4, 4), interior up-left', function (utest_name)
  local sprite_id = sprite_id_location(8, 0):to_sprite_id()
  local tcd = collision_data.get_tile_collision_data(sprite_id)
  assert_log(utest_name, are_same_with_message(tcd, tile_collision_data({8, 8, 8, 8, 8, 7, 6, 5}, {8, 8, 8, 8, 8, 7, 6, 5}, atan2(-4, 4), vertical_dirs.up, horizontal_dirs.left)))
end)

check('tile_collision_data.read_height_array on sprite_id_location(0, 0) should return an array with tile mask data: full', function (utest_name)
  local array = tile_collision_data.read_height_array(sprite_id_location(0, 2), vertical_dirs.down)
  assert_log(utest_name, are_same_with_message({8, 8, 8, 8, 8, 8, 8, 8}, array))
end)

-- bugfix history:
--  = after switching to pink transparency, all my tiles became square blocks
-- warning: it's a proto tile, if you strip it from final build later, test another tile instead
check('tile_collision_data.read_height_array on sprite_id_location(1, 7) return an array with tile mask data: ascending slope 45', function (utest_name)
  local array = tile_collision_data.read_height_array(sprite_id_location(1, 7), vertical_dirs.down)
  assert_log(utest_name, are_same_with_message({1, 2, 3, 4, 5, 6, 7, 8}, array))
end)

check('sonic_sprite_data_table preserved key "idle"', function (utest_name)
  assert_log(utest_name, playercharacter_data.sonic_sprite_data_table["idle"] ~= nil, 'Expected playercharacter_data.sonic_sprite_data_table["idle"] to not be nil')
end)

check('sonic_animated_sprite_data_table preserved key "idle"', function (utest_name)
  assert_log(utest_name, playercharacter_data.sonic_animated_sprite_data_table["idle"] ~= nil, 'Expected playercharacter_data.sonic_animated_sprite_data_table["idle"] to not be nil')
end)
