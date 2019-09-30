--#ifn pico8

require("engine/test/pico8api")
local tile = require("platformer/tile")
local collision_data = require("data/collision_data")
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
  fset(73, sprite_flags.collision, true)  -- high-tile (3/4 filled)

  -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
  height_array_init_mock = stub(tile.height_array, "_init", function (self, tile_data)
    local tile_mask_id_location = tile_data.id_loc
    if tile_mask_id_location == collision_data.tiles_data[64].id_loc then
      self._array = {8, 8, 8, 8, 8, 8, 8, 8}  -- full tile
    elseif tile_mask_id_location == collision_data.tiles_data[65].id_loc then
      self._array = {1, 2, 3, 4, 5, 6, 7, 8}  -- ascending slope 45
    elseif tile_mask_id_location == collision_data.tiles_data[66].id_loc then
      self._array = {8, 7, 6, 5, 4, 3, 2, 1}  -- descending slope 45
    elseif tile_mask_id_location == collision_data.tiles_data[67].id_loc then
      self._array = {2, 2, 3, 3, 4, 4, 5, 5}  -- ascending slope 22.5
    elseif tile_mask_id_location == collision_data.tiles_data[68].id_loc then
      self._array = {8, 8, 7, 6, 6, 7, 6, 7}  -- wavy horizontal almost full tile
    elseif tile_mask_id_location == collision_data.tiles_data[70].id_loc then
      self._array = {4, 4, 4, 4, 4, 4, 4, 4}  -- half-tile (bottom half)
    elseif tile_mask_id_location == collision_data.tiles_data[71].id_loc then
      self._array = {0, 0, 0, 0, 4, 4, 4, 4}  -- quarter-tile (bottom-right quarter)
    elseif tile_mask_id_location == collision_data.tiles_data[72].id_loc then
      self._array = {2, 2, 2, 2, 2, 2, 2, 2}  -- low-tile (bottom quarter)
    elseif tile_mask_id_location == collision_data.tiles_data[73].id_loc then
      self._array = {6, 6, 6, 6, 6, 6, 6, 6}  -- high-tile (3/4 filled)
    else
      self._array = "invalid"
    end
    -- we trust the collision_data value to match our mockups
    -- if they don't, we need to override that value in the cases above
    self.slope_angle = tile_data.slope_angle
  end)

end

function tile_test_data.teardown()
  pico8:clear_spriteflags()

  height_array_init_mock:revert()
end

-- helper safety function that verifies that mock tile data is active when creating mock maps for utests
-- always use it instead of mset in utest setup meant to test collisions
function mock_mset(x, y, v)
  -- verify that tile_test_data.setup has been called since the last tile_test_data.teardown
  -- just check if the mock of height_array exists and is active
  assert(height_array_init_mock and not height_array_init_mock.reverted, "mock_mset: tile_test_data.setup has not been called since the last tile_test_data.teardown")
  mset(x, y, v)
end

return tile_test_data

--#endif
