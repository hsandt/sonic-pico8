local collision = require("engine/physics/collision")
local collision_data = require("game/data/collision_data")
local stub = require("luassert.stub")

local tile_test_data = {}

local height_array_init_mock

function tile_test_data.setup()
  -- mock sprite flags
  fset(1, sprite_flags.collision, true)   -- invalid tile (missing collision mask id location below)
  fset(64, sprite_flags.collision, true)  -- full tile
  fset(65, sprite_flags.collision, true)  -- ascending slope 45
  fset(66, sprite_flags.collision, true)  -- descending slope 45
  fset(67, sprite_flags.collision, true)  -- ascending slope 22.5 offset by 2
  fset(68, sprite_flags.collision, true)  -- wavy horizontal almost full tile
  fset(70, sprite_flags.collision, true)  -- half-tile (bottom half)
  fset(71, sprite_flags.collision, true)  -- quarter-tile (bottom-right half)
  fset(72, sprite_flags.collision, true)  -- low-tile (bottom quarter)

  -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
  height_array_init_mock = stub(collision.height_array, "_init", function (self, tile_mask_id_location, slope_angle)
    if tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[64] then
      self._array = {8, 8, 8, 8, 8, 8, 8, 8}  -- full tile
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[65] then
      self._array = {1, 2, 3, 4, 5, 6, 7, 8}  -- ascending slope 45
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[66] then
      self._array = {8, 7, 6, 5, 4, 3, 2, 1}  -- descending slope 45
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[67] then
      self._array = {2, 2, 3, 3, 4, 4, 5, 5}  -- ascending slope 22.5
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[68] then
      self._array = {8, 8, 7, 6, 6, 7, 6, 7}  -- wavy horizontal almost full tile
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[70] then
      self._array = {4, 4, 4, 4, 4, 4, 4, 4}  -- half-tile (bottom half)
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[71] then
      self._array = {0, 0, 0, 0, 4, 4, 4, 4}  -- quarter-tile (bottom half)
    elseif tile_mask_id_location == collision_data.sprite_id_to_collision_mask_id_locations[72] then
      self._array = {2, 2, 2, 2, 2, 2, 2, 2}  -- low-tile (bottom quarter)
    end
    self._slope_angle = slope_angle
  end)

end

function tile_test_data.teardown()
  fset(1, sprite_flags.collision, false)
  fset(64, sprite_flags.collision, false)
  fset(65, sprite_flags.collision, false)
  fset(66, sprite_flags.collision, false)
  fset(67, sprite_flags.collision, false)
  fset(68, sprite_flags.collision, false)
  fset(70, sprite_flags.collision, false)
  fset(71, sprite_flags.collision, false)
  fset(72, sprite_flags.collision, false)

  height_array_init_mock:revert()
end

return tile_test_data
