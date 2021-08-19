--#if game_constants
--(when using replace_strings with --game-constant-module-path [this_data.lua], all namespaced constants
-- below are replaced with their values (as strings), so this file can be skipped)

-- visual numerical data for in-game only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local visual_ingame_data = {
  spring_up_repr_tile_id = 74,              -- add 1 to get right part, must match value in tile_representation
                                            --  and location in ingame_sprite_data_t.spring (in visual_ingame_addon.lua)
  spring_left_repr_tile_id = 202,           -- just representing spring oriented to left on tilemap,
                                            --  we use the generic sprite rotated for rendering
  spring_right_repr_tile_id = 173,          -- just representing spring oriented to right on tilemap,
                                            --  we use the generic sprite rotated for rendering

  -- hiding leaves, must be known to detect emerald surrounded by them and render an extra hiding leaf
  --  on top of the emerald itself (via tilemap)
  hiding_leaves_id = 234,

  -- palm tree top representative tile is drawn via tilemap, so id is enough
  --  for extension sprites drawn around it, see ingame_sprite_data_t.palm_tree_leaves*
  --  (in visual_ingame_addon.lua)
  palm_tree_leaves_core_id = 236,

  -- launch ramp last tile
  launch_ramp_last_tile_id = 229,

  -- goal plate base id (representative tile used to generate animated sprite)
  goal_plate_base_id = 226,

  -- emerald_repr_sprite_id will be derived from sprite data, see visual_ingame_addon.lua
}

--(game_constants)
--#endif

return visual_ingame_data
