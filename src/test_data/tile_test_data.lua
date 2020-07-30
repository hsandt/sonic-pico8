--#if busted

-- pico8api should have been required in an including script,
-- since we are used busted, hence bustedhelper

local tile = require("platformer/tile")
local collision_data = require("data/collision_data")
local stub = require("luassert.stub")

local height_array_init_mock

-- IDs of tiles used for tests only (black and white in spritesheet, never used in real game)
no_tile_id = 0
full_tile_id = 32
half_tile_id = 80
flat_low_tile_id = 96
bottom_right_quarter_tile_id = 64
asc_slope_45_id = 112
desc_slope_45_id = 116
asc_slope_22_id = 113

-- symbol mapping for itests
-- (could also be used for utests instead of manual mock_mset, but need to extract parse_tilemap
--  from itest_dsl)
tile_symbol_to_ids = {
  ['.']  = no_tile_id,   -- empty
  ['#']  = full_tile_id,  -- full tile
  ['=']  = half_tile_id,  -- half tile (4px high)
  ['_']  = flat_low_tile_id,  -- flat low tile (2px high)
  ['r']  = bottom_right_quarter_tile_id,  -- bottom-right quarter tile (4px high)
  ['/']  = asc_slope_45_id,  -- ascending slope 45
  ['\\'] = desc_slope_45_id,  -- descending slope 45
  ['<']  = asc_slope_22_id,  -- ascending slope 22.5
}

local tile_test_data = {}

function tile_test_data.setup()
  -- mock sprite flags
  fset(1, sprite_flags.collision, true)   -- invalid tile (missing collision mask id location below)
  fset(full_tile_id, sprite_flags.collision, true)  -- full tile
  fset(asc_slope_45_id, sprite_flags.collision, true)  -- ascending slope 45
  fset(desc_slope_45_id, sprite_flags.collision, true)  -- descending slope 45
  fset(asc_slope_22_id, sprite_flags.collision, true)  -- ascending slope 22.5 offset by 2
  fset(half_tile_id, sprite_flags.collision, true)  -- half-tile (bottom half)
  fset(bottom_right_quarter_tile_id, sprite_flags.collision, true)  -- quarter-tile (bottom-right half)
  fset(flat_low_tile_id, sprite_flags.collision, true)  -- low-tile (bottom quarter)

  -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
  height_array_init_mock = stub(tile.height_array, "_init", function (self, tile_data)
    local tile_mask_id_location = tile_data.id_loc
    if tile_mask_id_location == collision_data.tiles_data[full_tile_id].id_loc then
      self._array = {8, 8, 8, 8, 8, 8, 8, 8}  -- full tile
    elseif tile_mask_id_location == collision_data.tiles_data[asc_slope_45_id].id_loc then
      self._array = {1, 2, 3, 4, 5, 6, 7, 8}  -- ascending slope 45
    elseif tile_mask_id_location == collision_data.tiles_data[desc_slope_45_id].id_loc then
      self._array = {8, 7, 6, 5, 4, 3, 2, 1}  -- descending slope 45
    elseif tile_mask_id_location == collision_data.tiles_data[asc_slope_22_id].id_loc then
      self._array = {2, 2, 3, 3, 4, 4, 5, 5}  -- ascending slope 22.5
    elseif tile_mask_id_location == collision_data.tiles_data[half_tile_id].id_loc then
      self._array = {4, 4, 4, 4, 4, 4, 4, 4}  -- half-tile (bottom half)
    elseif tile_mask_id_location == collision_data.tiles_data[bottom_right_quarter_tile_id].id_loc then
      self._array = {0, 0, 0, 0, 4, 4, 4, 4}  -- quarter-tile (bottom-right quarter)
    elseif tile_mask_id_location == collision_data.tiles_data[flat_low_tile_id].id_loc then
      self._array = {2, 2, 2, 2, 2, 2, 2, 2}  -- low-tile (bottom quarter)
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

--#endif

-- prevent busted from parsing both versions of tile_test_data
--[[#pico8

-- fallback implementation if busted symbol is not defined
-- (picotool fails on empty file due to empty self._tokens)
--#ifn busted
local tile_test_data = {"symbol tile_test_data is undefined"}
--#endif

--#pico8]]

return tile_test_data
