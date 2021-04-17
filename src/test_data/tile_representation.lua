-- this file is used by busted tests creating mock tilemaps on the go,
--  but also PICO-8 itests so we extracted it from tile_test_data
--  so it can be required safely from itest_dsl

local tile_repr = {
  -- IDs of tiles used for tests only (black and white in spritesheet, never used in real game)
  no_tile_id = 0,
  full_tile_id = 29,
  flat_high_tile_left_id = 26,
  flat_high_tile_id = 27,  -- TODO: use 2, it's the same
  half_tile_id = 4,
  flat_low_tile_id = 6,
  bottom_right_quarter_tile_id = 44,  -- test only
  asc_slope_22_id = 42,  -- test only
  asc_slope_22_upper_level_id = 43,  -- test only
  asc_slope_45_id = 21,
  desc_slope_45_id = 16,
  desc_slope_2px_id = 1,  -- low slope descending every 4px, from height 7 to 6, 2px total on connection
  -- because of the new convention of placing special sprite flags on visual tiles,
  --  for meaningful tests we separate both tiles and check that flags are verified
  --  on the right sprites. tilemap testing loop functionality should place the visual
  --  tile!
  visual_topleft_45 = 112,
  mask_topleft_45 = 32,
  visual_loop_topleft = 113,
  mask_loop_topleft = 33,  -- no more than a mask, alone it's a mere curved tile
  visual_loop_toptopleft = 114,
  mask_loop_toptopleft = 34,
  visual_loop_toptopright = 115,
  mask_loop_toptopright = 35,
  visual_loop_topright = 116,
  mask_loop_topright = 36,
  visual_topright_45 = 117,
  mask_topright_45 = 37,
  -- below have no representation as not used in DSL itests
  -- but useful for utests which directly mset with ID constants
  visual_loop_bottomleft = 97,
  mask_loop_bottomleft = 17,
  visual_loop_bottomright = 100,
  mask_loop_bottomright = 20,
  visual_loop_bottomright_steepest = 102,
  spring_up_repr_tile_id = 74,                   -- add 1 to get right, must match value in visual
  grass_top_decoration1 = 76,            -- no collider, just to test foreground
  oneway_platform_left = 35,             -- left side of one-way platform top part
}

  -- symbol mapping for itests
  -- (could also be used for utests instead of manual mock_mset, but need to extract parse_tilemap
  --  from itest_dsl)
tile_repr.tile_symbol_to_ids = {
  ['.']  = tile_repr.no_tile_id,   -- empty
  ['#']  = tile_repr.full_tile_id,  -- full tile
  ['-']  = tile_repr.flat_high_tile_id,  -- block 6x high
  ['=']  = tile_repr.half_tile_id,  -- half tile (4px high)
  ['_']  = tile_repr.flat_low_tile_id,  -- flat low tile (2px high)
  ['r']  = tile_repr.bottom_right_quarter_tile_id,  -- bottom-right quarter tile (4px high)
  ['<']  = tile_repr.asc_slope_22_id,  -- ascending slope 22.5 (legacy)
  ['y']  = tile_repr.asc_slope_22_upper_level_id,  -- ascending slope upper level 22.5 (actually 1:2)
  ['/']  = tile_repr.asc_slope_45_id,  -- ascending slope 45
  ['\\'] = tile_repr.desc_slope_45_id,  -- descending slope 45
  ['>'] = tile_repr.desc_slope_2px_id,
  ['4']  = tile_repr.visual_topleft_45,  -- 45-deg top-left ceiling slope
  ['Y']  = tile_repr.visual_loop_topleft,  -- loop top-left corner
  ['Z']  = tile_repr.visual_loop_toptopleft,   -- loop top-top-left corner (between flat top and top-left)
  ['R']  = tile_repr.visual_loop_toptopright,  -- loop top-top-right corner (between flat top and top-right)
  ['V']  = tile_repr.visual_loop_topright,  -- loop top-right corner
  ['5']  = tile_repr.visual_topright_45,  -- 45-deg top-right ceiling slope
  ['i']  = tile_repr.visual_loop_bottomright_steepest,
  ['s']  = tile_repr.spring_up_repr_tile_id,
  ['S']  = tile_repr.spring_up_repr_tile_id + 1,
  ['o']  = tile_repr.oneway_platform_left,
}

return tile_repr
