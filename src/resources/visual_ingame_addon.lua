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

  -- hiding leaves, must be known to detect emerald surrounded by them and render an extra hiding leaf
  --  on top of the emerald itself (via tilemap)
  hiding_leaves_id = 234,

  -- palm tree top representative tile is drawn via tilemap, so id is enough
  --  for extension sprites drawn around it, see ingame_sprite_data_t.palm_tree_leaves*
  palm_tree_leaves_core_id = 236,

  -- launch ramp last tile
  launch_ramp_last_tile_id = 229,

  -- goal plate base id (representative tile used to generate animated sprite)
  goal_plate_base_id = 226,

  -- emerald_repr_sprite_id will be derived from sprite data, see below
}

local ingame_sprite_data_t = transform(
  {
    -- sprite_data(id_loc: sprite_id_location([1], [2]), span: tile_vector([3], [4]), pivot: vector([5], [6]), transparent_color_arg: colors.pink),
    -- parameters:                        {id_loc(2), span(2), pivot(2)}

    -- palm tree extension sprites
    -- top pivot is located at top-left of core
    palm_tree_leaves_top                = {   12, 12,    1, 2,    0, 16},
    -- right side pivot is located at top-right of core
    -- left side is a mirror of right side, and must be placed just on the left of the core
    -- no multicolor transparency right now, but if you add sprites on the top-left of the palm tree leaves for compactness on the spritesheet,
    --  you can, but they must have no common colors with the leaves, and you must add all of their unique colors to the transparency list {color1, color2, ...}
    palm_tree_leaves_right              = {   13, 12,    3, 4,    0, 16},

    -- RUNTIME SPRITES (stage-specific and common runtime)
    -- below need runtime sprites to be reloaded, overwriting collision masks
    background_forest_bottom_hole       = {     1, 0,    2, 3,    0,  0},
    background_forest_bottom_lightshaft = {    13, 1,    3, 2,    0,  0},
    emerald_silhouette                  = {     9, 1,    1, 1,    3,  2},
    goal_plate_goal                     = {     3, 0,    3, 2,   12, 16},
    goal_plate_sonic                    = {     6, 0,    3, 2,   12, 16},
    goal_plate_rotating_90              = {     0, 1,    1, 2,    4, 16},

    -- rotating goal plates at 45 degrees are exceptions and placed in the common area despite only being used at runtime
    --  this is simply because there was no space left for sprites 2-tile high in the runtime area; hence the high location j
    goal_plate_rotating_45_ccw          = {    6, 14,    2, 2,    7, 16},
    goal_plate_rotating_45_cw           = {    8, 14,    2, 2,    8, 16},

    -- emerald representation tile (left part) and object sprite (both parts)
    emerald                             = {   10, 15,    1, 1,     3, 2},

    -- spring (pivot at bottom center on both sprites so it extends correctly)
    spring                              = {    10, 4,    2, 1,   10,  2},
    spring_extended                     = {    10, 5,    2, 2,   10, 10}
  },
  function (params)
    return sprite_data(sprite_id_location(params[1], params[2]), tile_vector(params[3], params[4]), vector(params[5], params[6]), colors.pink)
  end
)

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
