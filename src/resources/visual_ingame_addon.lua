local visual = require("resources/visual_common")

local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")

-- visual for in-game only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local ingame_visual = {
  spring_up_repr_tile_id = 74,              -- add 1 to get right part, must match value in tile_representation
                                            --  and location in ingame_sprite_data_t.spring
  spring_left_repr_tile_id = 202,           -- just representing spring oriented to left on tilemap,
                                            --  we use the generic sprite rotated for rendering
  spring_right_repr_tile_id = 173,          -- just representing spring oriented to right on tilemap,
                                            --  we use the generic sprite rotated for rendering

  -- palm tree top representative tile is drawn via tilemap, so id is enough
  --  for extension sprites drawn around it, see ingame_sprite_data_t.palm_tree_leaves*
  palm_tree_leaves_core_id = 236,

  -- launch ramp last tile
  launch_ramp_last_tile_id = 229,

  -- goal plate base id (representative tile used to generate animated sprite)
  goal_plate_base_id = 226,

  -- emerald_repr_sprite_id will be derived from sprite data, see below
}

local ingame_sprite_data_t = {
  -- palm tree extension sprites
  -- top pivot is located at top-left of core
  palm_tree_leaves_top = sprite_data(sprite_id_location(12, 12), tile_vector(1, 2), vector(0, 16), colors.pink),
  -- right side pivot is located at top-right of core
  -- left side is a mirror of right side, and must be placed just on the left of the core
  -- we need multicolor transparency to exclude rock sprite located in the same rectangle for compactness
  palm_tree_leaves_right = sprite_data(sprite_id_location(13, 12), tile_vector(3, 4), vector(0, 16), {colors.pink, colors.black, colors.dark_blue, colors.indigo, colors.white}),

  -- RUNTIME SPRITES (stage-specific and common runtime)
  -- below need runtime sprites to be reloaded, overwriting collision masks
  background_forest_bottom_hole = sprite_data(sprite_id_location(1, 0), tile_vector(2, 3), vector(0, 0), colors.pink),
  emerald_silhouette = sprite_data(sprite_id_location(9, 1), nil, vector(3, 2), colors.pink),
  goal_plate_goal = sprite_data(sprite_id_location(3, 0), tile_vector(3, 2), vector(12, 16), colors.pink),
  goal_plate_sonic = sprite_data(sprite_id_location(6, 0), tile_vector(3, 2), vector(12, 16), colors.pink),
  goal_plate_rotating_90 = sprite_data(sprite_id_location(0, 1), tile_vector(1, 2), vector(4, 16), colors.pink),

  -- rotating goal plates at 45 degrees are exceptions and placed in the common area despite only being used at runtime
  --  this is simply because there was no space left for sprites 2-tile high in the runtime area; hence the high location j
  goal_plate_rotating_45_ccw = sprite_data(sprite_id_location(6, 14), tile_vector(2, 2), vector(7, 16), colors.pink),
  goal_plate_rotating_45_cw = sprite_data(sprite_id_location(8, 14), tile_vector(2, 2), vector(8, 16), colors.pink),

  -- emerald representation tile (left part) and object sprite (both parts)
  emerald = sprite_data(sprite_id_location(10, 15), nil, vector(3, 2), colors.pink),

  -- spring (pivot at bottom center on both sprites so it extends correctly)
  spring = sprite_data(sprite_id_location(10, 4), tile_vector(2, 1), vector(10, 2), colors.pink),
  spring_extended = sprite_data(sprite_id_location(10, 5), tile_vector(2, 2), vector(10, 10), colors.pink)
}

-- derived data: the representative sprite of an emerald (the one placed on the tilemap)
--  in the left part of the sprite, so convert id location (which is at top-left) to sprite ID
ingame_visual.emerald_repr_sprite_id = ingame_sprite_data_t.emerald.id_loc:to_sprite_id()

local ingame_animated_sprite_data_t = {
  goal_plate = {
    -- manual construction via sprite direct access appears longer than animated_sprite_data.create in code,
    --  but this will actually be minified and therefore very compact (as names are not protected)
    ["goal"] = animated_sprite_data.create_static(ingame_sprite_data_t.goal_plate_goal),
    ["sonic"] = animated_sprite_data.create_static(ingame_sprite_data_t.goal_plate_sonic),
    ["rotating"] = animated_sprite_data(
      {
        ingame_sprite_data_t.goal_plate_goal,
        ingame_sprite_data_t.goal_plate_rotating_45_ccw,
        ingame_sprite_data_t.goal_plate_rotating_90,
        ingame_sprite_data_t.goal_plate_rotating_45_cw,
        ingame_sprite_data_t.goal_plate_sonic,
        ingame_sprite_data_t.goal_plate_rotating_45_ccw,
        ingame_sprite_data_t.goal_plate_rotating_90,
        ingame_sprite_data_t.goal_plate_rotating_45_cw
      },
      3,
      4  -- anim_loop_modes.loop (will be stopped from code)
    )
  }
}

merge(visual, ingame_visual)
merge(visual.sprite_data_t, ingame_sprite_data_t)
merge(visual.animated_sprite_data_t, ingame_animated_sprite_data_t)
