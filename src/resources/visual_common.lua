local animated_sprite_data = require("engine/render/animated_sprite_data")
local sprite_data = require("engine/render/sprite_data")

-- visuals common to both cartridges
-- require visual_titlemenu/ingame for data add-on directly on this table
-- emeralds are shown in the pre-stage introduction, so needed for titlemenu
local visual = {
  -- emerald color palettes (apply to red emerald sprite to get them all)
  emerald_colors = {
    -- light color, dark color
    {colors.red, colors.dark_purple},
    {colors.peach, colors.orange},
    {colors.pink, colors.dark_purple},
    {colors.indigo, colors.dark_gray},
    {colors.blue, colors.dark_blue},
    {colors.green, colors.dark_green},
    {colors.yellow, colors.orange},
    {colors.orange, colors.brown},
  },

  -- for flash appearance animations, we need a palette that maps colors to their bright equivalent
  -- since we need an animation we define one per step
  -- we only use 2 steps: very bright and bright (use nor color swap to revert to original colors)
  bright_to_normal_palette_swap_sequence_by_original_color = {
    [colors.dark_gray] = {colors.white, colors.light_gray},
    [colors.light_gray] = {colors.white, colors.white},
    [colors.red] = {colors.white, colors.white},
    [colors.peach] = {colors.white, colors.white},
    [colors.pink] = {colors.white, colors.white},
    [colors.indigo] = {colors.white, colors.white},
    [colors.blue] = {colors.white, colors.white},
    [colors.green] = {colors.white, colors.white},
    [colors.yellow] = {colors.white, colors.white},
    [colors.orange] = {colors.white, colors.white},
    -- we don't define mappings for emerald darker colors, as we want custom
    --  dark to bright mapping ware of the original emerald color (see assess_result_async)
  }
}

-- transform bright_to_normal_palette_swap_sequence_by_original_color, a table of sequence of new color per original color
--  into a sequence (over steps 1, 2) of color palette swap (usable with pal)
--  by extracting new color i for each original color, for each step
visual.bright_to_normal_palette_swap_by_original_color_sequence = transform({1, 2}, function (step)
  return transform(visual.bright_to_normal_palette_swap_sequence_by_original_color, function (color_sequence)
    return color_sequence[step]
  end)
end)

local sprite_data_t = {
  -- COMMON INITIAL SPRITES
--#if mouse
  cursor = sprite_data(sprite_id_location(15, 4), nil, nil, colors.pink),
--#endif
  emerald = sprite_data(sprite_id_location(10, 15), tile_vector(2, 1), vector(4, 4), colors.pink),

  -- ANIMATION SPRITES
  emerald_pick_fx1 = sprite_data(sprite_id_location(12, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
  emerald_pick_fx2 = sprite_data(sprite_id_location(13, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
  emerald_pick_fx3 = sprite_data(sprite_id_location(14, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
  emerald_pick_fx4 = sprite_data(sprite_id_location(15, 0), tile_vector(1, 1), vector(4, 4), colors.pink),
}

visual.sprite_data_t = sprite_data_t

-- IN-GAME only, but more convenient to put it with other emerald visual data
-- derived data: the representative sprite of an emerald (the one placed on the tilemap)
--  in the left part of the sprite, so convert id location (which is at top-left) to sprite ID
visual.emerald_repr_sprite_id = sprite_data_t.emerald.id_loc:to_sprite_id()

-- ANIMATIONS
-- the pick action is in-game only, but since it is a sparkle it is convenient to liven up
--  the titlemenu as well (e.g. on the emblem or emeralds)
visual.animated_sprite_data_t = {
  emerald_pick_fx = {
    -- manual construction via sprite direct access appears longer than animated_sprite_data.create in code,
    --  but this will actually be minified and therefore very compact (as names are not protected)
    ["once"] = animated_sprite_data(
      {
        sprite_data_t.emerald_pick_fx1,
        sprite_data_t.emerald_pick_fx2,
        sprite_data_t.emerald_pick_fx3,
        sprite_data_t.emerald_pick_fx4
      },
      5,
      2  -- anim_loop_modes.freeze_last (just to sport forgotten fx clear easily)
    )
  },
}


-- drawing helpers (titlemenu will use them too)

-- render a cross at center (x, y) with branches of base length from center (excluding spike)
--  branch_base_length, half-width branch_half_width (width 2 * branch_half_width + 1 adding center pixel),
--  spiky ends and color c
function visual.draw_cross(x, y, branch_base_length, branch_half_width, c)
  -- horizontal white rectangle
  rectfill(x - branch_base_length, y - branch_half_width, x + branch_base_length, y + branch_half_width, c)
  -- vertical white rectangle
  rectfill(x - branch_half_width, y - branch_base_length, x + branch_half_width, y + branch_base_length, c)
  -- left and right white triangle spike (branch_half_width lines, last one being a dot)
  for sign = -1, 1, 2 do
    for i = 1, branch_half_width do
      line(x + sign * (branch_base_length + i), y - branch_half_width + i,
           x + sign * (branch_base_length + i), y + branch_half_width - i, c)
    end
  end
  -- up and down white triangle spike (branch_half_width lines, last one being a dot)
  for sign = -1, 1, 2 do
    for i = 1, branch_half_width do
      line(x - branch_half_width + i, y + sign * (branch_base_length + i),
           x + branch_half_width - i, y + sign * (branch_base_length + i), c)
    end
  end
end

-- render the emerald cross base and every picked emeralds
-- (x, y) is at cross center
function visual.draw_emerald_cross_base(x, y, palette_swap_table)
  -- we prefer using pal() to manually assign  palette_swap_table[c] to internal colors
  --  because when we want implicit default colors and the swap table is empty,
  --  the former will preserve colors, while the latter will interpret nil as 0
  -- also, it allows us to swap other colors than gray too
  pal(palette_swap_table)

  local internal_color1 = colors.dark_gray
  local internal_color2 = colors.light_gray

  visual.draw_cross(x, y, 11, 3, colors.white)
  -- dark and light gray crosses have the same base length!
  visual.draw_cross(x, y, 10, 2, internal_color1)
  visual.draw_cross(x, y, 10, 1, internal_color2)

  -- dark gray marks
  -- horizontal line (will have holes)
  line(x - 10, y, x + 10, y, internal_color1)
  -- vertical
  line(x, y - 10, x, y + 10, internal_color1)

  -- diagonals (faster to draw 4 diagonals than 4 mini orthogonal segments +
  --  4 dots in the diagonal directions to make cross smooth near the center)
  -- from top-left one, CW
  line(x - 5, y - 1, x - 1, y - 5, internal_color1)
  line(x + 1, y - 5, x + 5, y - 1, internal_color1)
  line(x + 5, y + 1, x + 1, y + 5, internal_color1)
  line(x - 1, y + 5, x - 5, y + 1, internal_color1)

  -- light gray holes
  -- again, the trick is to use diagonals rather than dots to cover 3 pixels at once
  --  (or only 2 when overlapping)
  -- from top-left, then CW
  -- compared to above, get closer to center just by remove -1/+1
  line(x - 5, y    , x    , y - 5, internal_color2)
  line(x    , y - 5, x + 5, y    , internal_color2)
  line(x + 5, y    , x    , y + 5, internal_color2)
  line(x    , y + 5, x - 5, y    , internal_color2)

  -- we left 4 dots placed on square corners in the middle
  --  cover them all with a square at once
  rectfill(x - 2, y - 2, x + 2, y + 2, internal_color2)

  -- make a roundy square rotated by 45 degrees with a circle
  circ(x, y, 2, internal_color1)

  -- draw the PICO-8 logo inside
  -- white square, will be covered by colors to make a cross
  rectfill(x - 1, y - 1, x + 1, y + 1, colors.white)
  pset(x    , y - 2, colors.red)
  pset(x + 1, y - 1, colors.peach)
  pset(x + 2, y    , colors.pink)
  pset(x + 1, y + 1, colors.indigo)
  pset(x    , y + 2, colors.blue)
  pset(x - 1, y + 1, colors.green)
  pset(x - 2, y    , colors.yellow)
  pset(x - 1, y - 1, colors.orange)

  pal()
end

return visual
