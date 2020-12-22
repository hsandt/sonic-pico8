local visual = require("resources/visual_common")

local sprite_data = require("engine/render/sprite_data")

local stage_clear_visual = {
  fadeout_zigzag_width = 11,  -- doesn't include pixel 0, so actually count +1 pixel in total
  missed_emeralds_radius = 15,

  -- use this table with pal() to recolor things darker (level 1-2, don't use at level 0)
  -- we skip black which doesn't get darker, so we can start at index 1 and we don't need
  --  explicit keys at all
  swap_palette_by_darkness = {
    -- [colors.black] = {colors.black, colors.black},
    --[[ [colors.dark_blue] = ]] {colors.black, colors.black},
    --[[ [colors.dark_purple] = ]] {colors.black, colors.black},
    --[[ [colors.dark_green] = ]] {colors.black, colors.black},
    --[[ [colors.brown] = ]] {colors.black, colors.black},
    --[[ [colors.dark_gray] = ]] {colors.black, colors.black},
    --[[ [colors.light_gray] = ]] {colors.dark_gray, colors.black},
    --[[ [colors.white] = ]] {colors.light_gray, colors.dark_gray},
    --[[ [colors.red] = ]] {colors.dark_purple, colors.black},
    --[[ [colors.orange] = ]] {colors.brown, colors.black},
    --[[ [colors.yellow] = ]] {colors.orange, colors.brown},
    --[[ [colors.green] = ]] {colors.dark_green, colors.black},
    --[[ [colors.blue] = ]] {colors.dark_blue, colors.black},
    --[[ [colors.indigo] = ]] {colors.dark_gray, colors.black},
    --[[ [colors.pink] = ]] {colors.dark_purple, colors.black},
    --[[ [colors.peach] = ]] {colors.orange, colors.brown}
  }
}

-- visuals for stage_clear only
-- it uses the add-on system, which means you only need to require it along with visual_common,
--  but only get the return value of visual_common named `visual` here
-- it will automatically add extra information to `visual`
local menu_sprite_data_t = {
  -- stage clear spritesheet is pretty busy as it must contain stage tiles, so we had to move menu cursor
  --  sprites to a different location than in titlemenu, that we define in this stage_clear-specific add-on
  menu_cursor = sprite_data(sprite_id_location(10, 0), tile_vector(2, 1), vector(8, 5), colors.pink),
}

merge(visual, stage_clear_visual)
merge(visual.sprite_data_t, menu_sprite_data_t)
