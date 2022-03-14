local visual = require("resources/visual_common")

local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")

local stage_intro_sprite_data_t = transform(
  {
    -- sprite_data(id_loc: sprite_id_location([1], [2]), span: tile_vector([3], [4]), pivot: vector([5], [6]), transparent_color_arg: colors.pink),
    -- parameters: {id_loc(2), span(2), pivot(2)}

    -- clouds (same as titlemenu addon)
    cloud_big    = {     0, 1,    7, 3,    0, 11},
    cloud_medium = {     7, 1,    4, 2,    0,  6},
    cloud_small  = {    11, 1,    3, 2,    0,  4},
    cloud_tiny   = {    14, 1,    2, 1,    0,  4},
  },
  function (params)
    return sprite_data(sprite_id_location(params[1], params[2]), tile_vector(params[3], params[4]), vector(params[5], params[6]), colors.pink)
  end
)

merge(visual.sprite_data_t, stage_intro_sprite_data_t)
