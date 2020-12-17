local visual = require("resources/visual_common")

local sprite_data = require("engine/render/sprite_data")

local titlemenu_visual = {
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
  }
}

-- visuals for titlemenu only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local titlemenu_sprite_data_t = {
  menu_cursor = sprite_data(sprite_id_location(1, 0), tile_vector(2, 1), vector(8, 5), colors.pink),
  menu_cursor_shoe = sprite_data(sprite_id_location(3, 0), tile_vector(2, 1), vector(8, 5), colors.pink),
  title_logo = sprite_data(sprite_id_location(0, 1), tile_vector(14, 10), nil, colors.pink),
  angel_island_bg = sprite_data(sprite_id_location(0, 11), tile_vector(16, 5), nil, colors.pink),
  -- true emerald is located where emerald silhouette is in visual_ingame_addon
  emerald = sprite_data(sprite_id_location(10, 0), nil, vector(3, 2), colors.pink),
}

merge(visual, titlemenu_visual)
merge(visual.sprite_data_t, titlemenu_sprite_data_t)
