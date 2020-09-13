-- this file is used by busted tests creating mock tilemaps on the go,
--  but also PICO-8 itests so we extracted it from tile_test_data
--  so it can be required safely from itest_dsl

-- IDs of tiles used for tests only (black and white in spritesheet, never used in real game)
no_tile_id = 0
full_tile_id = 32
half_tile_id = 80
flat_low_tile_id = 96
bottom_right_quarter_tile_id = 64
asc_slope_22_id = 112
asc_slope_22_upper_level_id = 117
asc_slope_45_id = 113
desc_slope_45_id = 116
-- because of the new convention of placing special sprite flags on visual tiles,
--  for meaningful tests we separate both tiles and check that flags are verified
--  on the right sprites. tilemap testing loop functionality should place the visual
--  tile!
visual_loop_topleft = 8
mask_loop_topleft = 12  -- no more than a mask, alone it's a mere curved tile
visual_loop_toptopleft = 9
mask_loop_toptopleft = 13
visual_loop_toptopright = 10
mask_loop_toptopright = 14
-- below have no representation as not used in DSL itests
-- but useful for utests which directly mset with ID constants
visual_loop_bottomleft = 56
mask_loop_bottomleft = 60
visual_loop_bottomright = 59
mask_loop_bottomright = 63
spring_id = 5

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
  ['s'] = spring_id,
}
