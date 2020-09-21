-- this file is used by busted tests creating mock tilemaps on the go,
--  but also PICO-8 itests so we extracted it from tile_test_data
--  so it can be required safely from itest_dsl

-- IDs of tiles used for tests only (black and white in spritesheet, never used in real game)
no_tile_id = 0
full_tile_id = 29
flat_high_tile_left_id = 26
flat_high_tile_id = 27
half_tile_id = 4
flat_low_tile_id = 6
bottom_right_quarter_tile_id = 44  -- test only
asc_slope_22_id = 42  -- test only
asc_slope_22_upper_level_id = 43  -- test only
asc_slope_45_id = 21
desc_slope_45_id = 16
-- because of the new convention of placing special sprite flags on visual tiles,
--  for meaningful tests we separate both tiles and check that flags are verified
--  on the right sprites. tilemap testing loop functionality should place the visual
--  tile!
visual_loop_topleft = 113
mask_loop_topleft = 33  -- no more than a mask, alone it's a mere curved tile
visual_loop_toptopleft = 114
mask_loop_toptopleft = 34
visual_loop_toptopright = 115
mask_loop_toptopright = 35
-- below have no representation as not used in DSL itests
-- but useful for utests which directly mset with ID constants
visual_loop_bottomleft = 97
mask_loop_bottomleft = 17
visual_loop_bottomright = 100
mask_loop_bottomright = 20
spring_left_id = 74                   -- add 1 to get right

-- symbol mapping for itests
-- (could also be used for utests instead of manual mock_mset, but need to extract parse_tilemap
--  from itest_dsl)
tile_symbol_to_ids = {
  ['.']  = no_tile_id,   -- empty
  ['#']  = full_tile_id,  -- full tile
  ['=']  = half_tile_id,  -- half tile (4px high)
  ['_']  = flat_low_tile_id,  -- flat low tile (2px high)
  ['r']  = bottom_right_quarter_tile_id,  -- bottom-right quarter tile (4px high)
  ['<']  = asc_slope_22_id,  -- ascending slope 22.5 (legacy)
  ['y']  = asc_slope_22_upper_level_id,  -- ascending slope upper level 22.5 (actually 1:2)
  ['/']  = asc_slope_45_id,  -- ascending slope 45
  ['\\'] = desc_slope_45_id,  -- descending slope 45
  ['Y'] = visual_loop_topleft,  -- loop top-left corner
  ['Z'] = visual_loop_toptopleft,   -- loop top-top-left corner (between flat top and top-left)
  ['R'] = visual_loop_toptopright,  -- loop top-top-right corner (between flat top and top-right)
  ['s'] = spring_left_id,
  ['S'] = spring_left_id + 1,
}
