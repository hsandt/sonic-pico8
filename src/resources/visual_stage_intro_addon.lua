local visual = require("resources/visual_common")

local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")

local stage_intro_visual = {
  -- water parts copied from titlemenu_visual
  -- if we also add them to ingame eventually, just merge all of them into
  -- visual_common

  -- water shimmer animation period
  water_shimmer_period = 1.3,

  -- color swap for water shimmers, index by time step, by original color index
  --  (1 for red, 2 for yellow)
  water_shimmer_color_cycle = {
    {colors.dark_blue, colors.light_gray},
    {colors.indigo, colors.light_gray},
    {colors.light_gray, colors.light_gray},
    {colors.light_gray, colors.indigo},
    {colors.light_gray, colors.dark_blue},
    {colors.light_gray, colors.dark_blue},
    {colors.light_gray, colors.indigo},
    {colors.indigo, colors.indigo},
  },
}

local stage_intro_sprite_data_t = transform(
  {
    -- sprite_data(id_loc: sprite_id_location([1], [2]), span: tile_vector([3], [4]), pivot: vector([5], [6]), transparent_color_arg: colors.pink),
    -- parameters:      {id_loc(2), span(2), pivot(2)}

    -- clouds (same as titlemenu addon)
    cloud_big         = {    0,  1,   7, 3,    0, 11},
    cloud_medium      = {    7,  1,   4, 2,    0,  6},
    cloud_small       = {   11,  1,   3, 2,    0,  4},
    cloud_tiny        = {   14,  1,   2, 1,    0,  4},

    -- horizon
    horizon_gradient  = {   11, 14,   1, 2,    0, 12},
    island            = {   12, 13,   4, 3,    0, 16},

    -- forest
    bg_forest_top     = {    0, 10,   4, 1,    0,  0},
    bg_forest_center  = {    0, 11,   4, 1,    0,  0},
    fg_leaves_top     = {    0, 12,   2, 1,    0,  0},
    fg_leaves_center  = {    0, 13,   2, 2,    0,  0},
    fg_leaves_bottom  = {    0, 15,   2, 1,    0,  0},
  },
  function (params)
    return sprite_data(sprite_id_location(params[1], params[2]), tile_vector(params[3], params[4]), vector(params[5], params[6]), colors.pink)
  end
)

merge(visual, stage_intro_visual)
merge(visual.sprite_data_t, stage_intro_sprite_data_t)
