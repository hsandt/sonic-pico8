require("engine/test/unittest")
require("engine/core/math")
local collision = require("engine/physics/collision")
local height_array = collision.height_array

check('. height_array._fill_array should fill the array with tile mask data: full', function ()
  local array = {}
  height_array._fill_array(array, sprite_id_location(0, 5))
  assert(are_same_with_message({8, 8, 8, 8, 8, 8, 8, 8}, array))
end)
