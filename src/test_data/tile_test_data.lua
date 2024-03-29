--#if busted

-- pico8api should have been required in an including script,
-- since we are used busted, hence bustedhelper

local collision_data = require("data/collision_data")
local tile_collision_data = require("data/tile_collision_data")
local stub = require("luassert.stub")
local tile_repr = require("test_data/tile_representation")

-- some tiles are defined in visual_ingame_numerical_data for use in real game, but they are not in tile_representation.lua
--  to avoid redundancy or because we didn't need them in itests yet
visual_ingame_data = require("resources/visual_ingame_numerical_data")

-- we should require ingameadd-on in main

local mock_raw_tile_collision_data = {
  -- collision_data values + PICO-8 spritesheet must match our mockup data
  -- REFACTOR: put all common data (collision mask id/location and slope angle) in common
  --  and only replace tile collision mask in PICO-8 spritesheet with height array for busted
  -- another waste is that tiles pointing to the same collision mask must duplicate
  --  height arrays, like half_tile_id and spring_up_repr_tile_id

  -- note that the first value is the collision mask sprite id, NOT the original sprite id in the key
  --  so they may differ when not working with prototype tiles
  [tile_repr.full_tile_id] = {tile_repr.full_tile_id, {8, 8, 8, 8, 8, 8, 8, 8}, {8, 8, 8, 8, 8, 8, 8, 8}, atan2(8, 0)},
  [tile_repr.flat_high_tile_left_id] = {tile_repr.flat_high_tile_left_id, {0, 0, 0, 0, 6, 6, 6, 6}, {0, 0, 4, 4, 4, 4, 4, 4}, atan2(8, 0)},
  [tile_repr.flat_high_tile_id] = {tile_repr.flat_high_tile_id, {6, 6, 6, 6, 6, 6, 6, 6}, {0, 0, 8, 8, 8, 8, 8, 8}, atan2(8, 0)},
  [tile_repr.half_tile_id] = {tile_repr.half_tile_id, {4, 4, 4, 4, 4, 4, 4, 4}, {0, 0, 0, 0, 8, 8, 8, 8}, atan2(8, 0)},
  [tile_repr.flat_low_tile_id] = {tile_repr.flat_low_tile_id, {2, 2, 2, 2, 2, 2, 2, 2}, {0, 0, 0, 0, 0, 0, 8, 8}, atan2(8, 0)},
  -- kept for testing; there is no *longer* edge so by convention we pick an angle so the interior is down... it won't detect reverse collisions coming horizontally
  [tile_repr.bottom_right_quarter_tile_id] = {tile_repr.bottom_right_quarter_tile_id, {0, 0, 0, 0, 4, 4, 4, 4}, {0, 0, 0, 0, 4, 4, 4, 4}, atan2(8, 0)},
  [tile_repr.asc_slope_22_id] = {tile_repr.asc_slope_22_id, {2, 2, 3, 3, 4, 4, 5, 5}, {0, 0, 0, 2, 4, 6, 8, 8}, 0.0625},
  [tile_repr.asc_slope_22_upper_level_id] = {tile_repr.asc_slope_22_upper_level_id, {5, 5, 6, 6, 7, 7, 8, 8}, {2, 4, 6, 8, 8, 8, 8, 8}, atan2(8, -4)},
  [tile_repr.asc_slope_45_id] = {tile_repr.asc_slope_45_id, {1, 2, 3, 4, 5, 6, 7, 8}, {1, 2, 3, 4, 5, 6, 7, 8}, atan2(8, -8)},
  [tile_repr.desc_slope_45_id] = {tile_repr.desc_slope_45_id, {8, 7, 6, 5, 4, 3, 2, 1}, {1, 2, 3, 4, 5, 6, 7, 8}, atan2(8, 8)},
  [tile_repr.desc_slope_2px_id] = {tile_repr.desc_slope_2px_id, {7, 7, 7, 7, 6, 6, 6, 6}, {0, 4, 8, 8, 8, 8, 8, 8}, atan2(8, 2)},
  [tile_repr.desc_slope_2px_last_id] = {tile_repr.desc_slope_2px_last_id, {1, 1, 1, 1, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 4}, atan2(8, 2), true},
  [tile_repr.desc_slope_4px_last_id_loop_variant] = {tile_repr.desc_slope_4px_last_id_loop_variant, {3, 3, 2, 2, 1, 1, 0, 0}, {0, 0, 0, 0, 0, 2, 4, 6}, atan2(8, 4), true},
  [tile_repr.visual_topleft_45] = {tile_repr.mask_topleft_45, {8, 7, 6, 5, 4, 3, 2, 1}, {8, 7, 6, 5, 4, 3, 2, 1}, atan2(-8, 8)},
  [tile_repr.visual_loop_topleft] = {tile_repr.mask_loop_topleft, {8, 7, 6, 6, 5, 4, 4, 3}, {8, 8, 8, 7, 5, 4, 2, 1}, atan2(-8, 5)},
  [tile_repr.visual_loop_toptopleft] = {tile_repr.mask_loop_toptopleft, {3, 2, 2, 1, 1, 0, 0, 0}, {5, 3, 1, 0, 0, 0, 0, 0}, atan2(-8, 3)},
  [tile_repr.visual_loop_toptopright] = {tile_repr.mask_loop_toptopright, {0, 0, 0, 1, 1, 2, 2, 3}, {5, 3, 1, 0, 0, 0, 0, 0}, atan2(-8, -3)},
  [tile_repr.visual_loop_topright] = {tile_repr.mask_loop_topright, {3, 4, 4, 5, 6, 6, 7, 8}, {8, 8, 8, 7, 5, 4, 2, 1}, atan2(-8, -5)},
  [tile_repr.visual_topright_45] = {tile_repr.mask_topright_45, {1, 2, 3, 4, 5, 6, 7, 8}, {8, 7, 6, 5, 4, 3, 2, 1}, atan2(-8, -8)},
  [tile_repr.visual_loop_bottomleft] = {tile_repr.mask_loop_bottomleft, {8, 7, 6, 6, 5, 4, 4, 3}, {1, 2, 4, 5, 7, 8, 8, 8}, atan2(8, 5)},
  [tile_repr.visual_loop_bottomright] = {tile_repr.mask_loop_bottomright, {3, 4, 4, 5, 6, 6, 7, 8}, {1, 2, 4, 5, 7, 8, 8, 8}, atan2(8, -5)},
  [tile_repr.visual_loop_bottomright_steepest] = {22, {0, 0, 0, 0, 0, 2, 5, 7}, {1, 1, 1, 2, 2, 2, 3, 3}, atan2(3, -8)},
  -- note that we didn't add definitions for mask_ versions, as we don't use them in tests
  -- if we need them, then since content is the same, instead of duplicating lines for mask_,
  --  after this table definition, just define mock_raw_tile_collision_data[mask_X] = mock_raw_tile_collision_data[visual_X] for X: loop tile locations
  [tile_repr.spring_up_repr_tile_id] = {tile_repr.flat_high_tile_left_id, {0, 0, 0, 0, 6, 6, 6, 6}, {0, 0, 4, 4, 4, 4, 4, 4}, atan2(8, 0)},  -- copied from flat_high_tile_left_id
  [tile_repr.spring_up_repr_tile_id + 1] = {tile_repr.flat_high_tile_id, {6, 6, 6, 6, 6, 6, 6, 6}, {0, 0, 8, 8, 8, 8, 8, 8}, atan2(8, 0)},   -- copied from flat_high_tile_id
  [tile_repr.spring_right_mask_repr_tile_id] = {tile_repr.spring_right_mask_repr_tile_id, {8, 8, 8, 8, 8, 8, 0, 0}, {6, 6, 6, 6, 6, 6, 6, 6}, atan2(0, 8)},
  [visual_ingame_data.launch_ramp_last_tile_id] = {tile_repr.mask_loop_bottomright, {3, 4, 4, 5, 6, 6, 7, 8}, {1, 2, 4, 5, 7, 8, 8, 8}, atan2(8, -5)},   -- copied from visual_loop_bottomright
  [tile_repr.oneway_platform_left] = {tile_repr.oneway_platform_left, {8, 8, 8, 8, 8, 8, 8, 8}, {8, 8, 8, 8, 8, 8, 8, 8}, atan2(8, 0)},
}

-- process data above to generate interior_v/h automatically, so we don't have to add them manually
--  for each tile (and it's actually what PICO-8 build does in collision_data to define tiles_collision_data)
local mock_tile_collision_data = transform(mock_raw_tile_collision_data, function(raw_data)
  local slope_angle = raw_data[4]
  local interior_v, interior_h = tile_collision_data.slope_angle_to_interiors(slope_angle)

  return tile_collision_data(
    sprite_id_location.from_sprite_id(raw_data[1]),
    raw_data[2],
    raw_data[3],
    slope_angle,
    interior_v,
    interior_h,
    raw_data[5]
  )
end)

local tile_test_data = {}

function tile_test_data.setup()
  -- mock sprite flags
  -- this includes "visual" sprites like springs!

  -- collision masks / proto tiles
  fset(tile_repr.full_tile_id, sprite_masks.collision + sprite_masks.midground)  -- full tile
  fset(tile_repr.flat_high_tile_left_id, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.flat_high_tile_id, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.half_tile_id, sprite_masks.collision + sprite_masks.midground)  -- half-tile (bottom half)
  fset(tile_repr.flat_low_tile_id, sprite_masks.collision + sprite_masks.midground)  -- low-tile (bottom quarter)
  fset(tile_repr.bottom_right_quarter_tile_id, sprite_masks.collision + sprite_masks.midground)  -- quarter-tile (bottom-right half)
  fset(tile_repr.asc_slope_22_id, sprite_masks.collision + sprite_masks.midground)  -- ascending slope 22.5 offset tile_repr.by 2 (legacy)
  fset(tile_repr.asc_slope_22_upper_level_id, sprite_masks.collision + sprite_masks.midground)  -- ascending slope 22.5 offset tile_repr.by 4
  fset(tile_repr.asc_slope_45_id, sprite_masks.collision + sprite_masks.midground)  -- ascending slope 45
  fset(tile_repr.desc_slope_45_id, sprite_masks.collision + sprite_masks.midground)  -- descending slope 45
  fset(tile_repr.desc_slope_2px_id, sprite_masks.collision + sprite_masks.midground)  -- descending slope every 4px, from height 7 to 6
  fset(tile_repr.desc_slope_2px_last_id, sprite_masks.collision + sprite_masks.midground)  -- descending slope every 4px, from height 1 to 0
  fset(tile_repr.desc_slope_4px_last_id_loop_variant, sprite_masks.collision + sprite_masks.ignore_loop_layer + sprite_masks.midground)  -- descending slope every 2px, from height 3 to 0

  -- masks also have collision flag, but only useful to test
  -- a non-loop proto curve tile with the same shape (as loop require visual tiles anyway)

  fset(tile_repr.visual_topleft_45, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_topleft_45, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_topleft, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_loop_topleft, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_toptopleft, sprite_masks.collision +  sprite_masks.midground)
  fset(tile_repr.mask_loop_toptopleft, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_toptopright, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_loop_toptopright, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_bottomleft, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_loop_bottomleft, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_topright, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_loop_topright, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_topright_45, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_topright_45, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_bottomright, sprite_masks.collision + sprite_masks.midground)
  fset(tile_repr.mask_loop_bottomright, sprite_masks.collision + sprite_masks.midground)

  fset(tile_repr.visual_loop_bottomright_steepest, sprite_masks.collision + sprite_masks.midground)

  -- spring
  fset(tile_repr.spring_up_repr_tile_id, sprite_masks.collision + sprite_masks.spring + sprite_masks.midground)
  fset(tile_repr.spring_up_repr_tile_id + 1, sprite_masks.collision + sprite_masks.spring + sprite_masks.midground)
  -- spring mask
  fset(tile_repr.spring_right_mask_repr_tile_id, sprite_masks.collision + sprite_masks.midground)

  -- ramp (last tile is one-way)
  fset(visual_ingame_data.launch_ramp_last_tile_id, sprite_masks.collision + sprite_masks.oneway + sprite_masks.midground)

  -- one-way platform
  fset(tile_repr.oneway_platform_left, sprite_masks.collision + sprite_masks.oneway + sprite_masks.midground)

  -- grass
  fset(tile_repr.grass_top_decoration1, sprite_masks.foreground)

  -- mock height array init so it doesn't have to dig in sprite data, inaccessible from busted
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
