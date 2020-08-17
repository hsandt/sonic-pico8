--#if busted

-- pico8api should have been required in an including script,
-- since we are used busted, hence bustedhelper

local collision_data = require("data/collision_data")
local tile_collision_data = require("data/tile_collision_data")
local stub = require("luassert.stub")
require("test_data/tile_representation")

local mock_tile_collision_data = {
  -- collision_data values + PICO-8 spritesheet must match our mockup data
  [full_tile_id] = tile_collision_data({8, 8, 8, 8, 8, 8, 8, 8}, {8, 8, 8, 8, 8, 8, 8, 8}, atan2(8, 0)),
  [half_tile_id] = tile_collision_data({4, 4, 4, 4, 4, 4, 4, 4}, {0, 0, 0, 0, 8, 8, 8, 8}, atan2(8, 0)),
  [flat_low_tile_id] = tile_collision_data({2, 2, 2, 2, 2, 2, 2, 2}, {0, 0, 0, 0, 0, 0, 8, 8}, atan2(8, 0)),
  [bottom_right_quarter_tile_id] = tile_collision_data({0, 0, 0, 0, 4, 4, 4, 4}, {0, 0, 0, 0, 4, 4, 4, 4}, atan2(8, 0)),
  [asc_slope_45_id] = tile_collision_data({1, 2, 3, 4, 5, 6, 7, 8}, {1, 2, 3, 4, 5, 6, 7, 8}, atan2(8, -8)),
  [asc_slope_22_id] = tile_collision_data({2, 2, 3, 3, 4, 4, 5, 5}, {0, 0, 0, 2, 4, 6, 8, 8}, 0.0625),
  [desc_slope_45_id] = tile_collision_data({8, 7, 6, 5, 4, 3, 2, 1}, {1, 2, 3, 4, 5, 6, 7, 8}, atan2(8, 8)),
  [asc_slope_22_upper_level_id] = tile_collision_data({5, 5, 6, 6, 7, 7, 8, 8}, {2, 4, 6, 8, 8, 8, 8, 8}, atan2(8, -4)),
  [loop_topleft] = tile_collision_data({8, 8, 8, 8, 8, 7, 6, 5}, {8, 8, 8, 8, 8, 7, 6, 5}, atan2(-4, 4)),
}

local tile_test_data = {}

function tile_test_data.setup()
  -- mock sprite flags
  fset(1, sprite_flags.collision, true)   -- invalid tile (missing collision mask id location below)
  fset(full_tile_id, sprite_flags.collision, true)  -- full tile
  fset(half_tile_id, sprite_flags.collision, true)  -- half-tile (bottom half)
  fset(flat_low_tile_id, sprite_flags.collision, true)  -- low-tile (bottom quarter)
  fset(bottom_right_quarter_tile_id, sprite_flags.collision, true)  -- quarter-tile (bottom-right half)
  fset(asc_slope_45_id, sprite_flags.collision, true)  -- ascending slope 45
  fset(asc_slope_22_id, sprite_flags.collision, true)  -- ascending slope 22.5 offset by 2
  fset(desc_slope_45_id, sprite_flags.collision, true)  -- descending slope 45
  fset(loop_topleft, sprite_flags.collision, true)  -- low-tile (bottom quarter)

  -- mock height array _init so it doesn't have to dig in sprite data, inaccessible from busted
  stub(collision_data, "get_tile_collision_data", function (current_tile_id)
    return mock_tile_collision_data[current_tile_id]
  end)
end

function tile_test_data.teardown()
  pico8:clear_spriteflags()

  collision_data.get_tile_collision_data:revert()
end

-- helper safety function that verifies that mock tile data is active when creating mock maps for utests
-- always use it instead of mset in utest setup meant to test collisions
function mock_mset(x, y, v)
  -- verify that tile_test_data.setup has been called since the last tile_test_data.teardown
  -- just check if the mock of height_array exists and is active
  assert(collision_data.get_tile_collision_data and not collision_data.get_tile_collision_data.reverted, "mock_mset: tile_test_data.setup has not been called since the last tile_test_data.teardown")
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
