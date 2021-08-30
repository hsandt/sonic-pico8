local visual = require("resources/visual_common")  -- we should require ingameadd-on in main

local visual_stage = {}

local function draw_full_line(y, c)
  line(0, y, 127, y, c)
end

-- below is stripped from itests to spare characters as we don't test aesthetics
-- we only strip body of render_background so we don't
--  have to strip their calls too

-- render the stage background
function visual_stage.render_background(camera_pos)
--#ifn itest

  -- always draw full sky background to be safe
  camera()
  rectfill(0, 0, 127, 127, colors.dark_blue)

  -- horizon line serves as a reference for the background
  --  and moves down slowly when camera moves up
  local horizon_line_dy = 156 - 0.5 * camera_pos.y
  camera(0, -horizon_line_dy)

  -- only draw sky and sea if camera is high enough

  -- -31 is based on the offset y 31 of the highest trees
  -- basically, when the top of the trees goes lower than the top of the screen,
  --  you start seeing the sea, so you can start drawing the sea decorations
  --  (note that the sea background itself is always rendered above, so it's quite safe at the border)
  if horizon_line_dy >= -31 then
    visual_stage.draw_background_sea(camera_pos)
  end

  -- draw forest bottom first as it contains the big uniform background that may
  --  cover forest top if it was drawn before

  -- 58 was tuned to start showing forest bottom when the lowest forest leaf starts going
  --  higher than the screen bottom
  if horizon_line_dy <= 58 then
    visual_stage.draw_background_forest_bottom(camera_pos, horizon_line_dy)
  end

  visual_stage.draw_background_forest_top(camera_pos)
--#endif
end

--#ifn itest

function visual_stage.draw_background_sea(camera_pos)
  -- blue line above horizon line
  draw_full_line(- 1, colors.blue)
  -- white horizon line
  draw_full_line(0, colors.white)
  draw_full_line(1, colors.indigo)

  -- clouds in the sky, from lowest to highest (and biggest)
  local cloud_dx_list_per_j = {
    {0, 60, 140, 220},
    {30, 150, 240},
    {10, 90, 210},
    {50, 130}
  }
  local dy_list_per_j = {
    {0, 0, -1, 0},
    {0, -1, -1, 0},
    {0, -1, 1, 0},
    {0, 1, -1, 1}
  }
  for j = 0, 3 do
    for cloud_dx in all(cloud_dx_list_per_j[j + 1]) do
      visual_stage.draw_cloud(cloud_dx, - --[[dy0]] 8.9 - --[[dy_mult]] 14.7 * j,
        dy_list_per_j[j + 1], --[[r0]] 2 + --[[r_mult]] 0.9 * j,
        --[[speed0]] 3 + --[[speed_mult]] 3.5 * j)
    end
  end

  -- shiny reflections in water
  -- vary y
  local reflection_dy_list = {4, 3, 6, 2, 1, 5}
  local period_list = {0.7, 1.5, 1.2, 1.7, 1.1}
  -- parallax speed of (relatively) close reflection (dy = 6)
  local water_parallax_speed_max = 0.015
  -- to cover up to ~127 with intervals of 6,
  --  we need i up to 21 since 21*6 = 126
  for i = 0, 21 do
    local dy = reflection_dy_list[i % 6 + 1]
    local y = 2 + dy
    -- elements farther from camera have slower parallax speed, closest has base parallax speed
    -- clamp in case some y are bigger than 6, but it's better if you can adjust to max of
    --  reflection_dy_list so max is still max and different dy give different speeds
    -- we have speed 0 at the horizon line, so no need to compute min
    -- note that real optics would give some 1 / tan(distance) factor but linear is enough for us
    local parallax_speed = water_parallax_speed_max * min(6, dy) / 6
    local parallax_offset = flr(parallax_speed * camera_pos.x)
    visual_stage.draw_water_reflections(parallax_offset, 6 * i, y, period_list[i % 5 + 1])
  end
end

function visual_stage.draw_background_forest_top(camera_pos)
  -- tree/leaves data

  -- parallax speed of farthest row
  local tree_row_parallax_speed_min = 0.3
  -- parallax speed of closest row
  local tree_row_parallax_speed_max = 0.42
  local tree_row_parallax_speed_range = tree_row_parallax_speed_max - tree_row_parallax_speed_min

  -- for max parallax speed, reuse the one of trees
  -- indeed, if you play S3 Angel Island, you'll notice that the highest falling leave row
  --  is actually the same sprite as the closest tree top (which is really just a big green patch)
  -- due to a small calculation error the final speeds end slightly different, so if you really
  --  want both elements to move exactly together, prefer drawing a long line from tree top to leaf bottom
  --  in a single draw_tree_and_leaves function
  -- however we use different speeds for farther leaves
  local leaves_row_parallax_speed_min = 0.36
  local leaves_row_parallax_speed_range = tree_row_parallax_speed_max - leaves_row_parallax_speed_min

  -- leaves (before trees so trees can hide some leaves with base height too long if needed)
  for j = 0, 1 do
    local parallax_speed = leaves_row_parallax_speed_min + leaves_row_parallax_speed_range * j  -- actually j / 1 where 1 is max j
    local parallax_offset = flr(parallax_speed * camera_pos.x)
    -- first patch of leaves chains from closest trees, so no base height
    --  easier to connect and avoid hiding closest trees
    visual_stage.draw_leaves_row(parallax_offset, 31 + --[[leaves_row_dy_mult]] 18 * (1 - j), --[[leaves_base_height]] 19, j,
      j % 2 == 1 and colors.green or colors.dark_green)
  end

  -- tree rows
  for j = 0, 2 do
    -- elements farther from camera have slower parallax speed, closest has base parallax speed
    local parallax_speed = tree_row_parallax_speed_min + tree_row_parallax_speed_range * j / 3
    local parallax_offset = flr(parallax_speed * camera_pos.x)
    -- tree_base_height ensures that trees have a bottom part long enough to cover the gap with the trees below
    visual_stage.draw_tree_row(parallax_offset, 31 + --[[tree_row_dy_mult]] 8 * j, --[[tree_base_height]] 10, j,
      j % 2 == 0 and colors.green or colors.dark_green)
  end
end

function visual_stage.draw_background_forest_bottom(camera_pos, horizon_line_dy)
  -- under the trees background (since we set camera y to - horizon_line_dy previously,
  --  a rectfill down to 127 - horizon_line_dy will effectively cover the bottom of the screen)
  --  to the screen bottom to cover anything left)

  -- for very dark green we dither between dark green and black using fill pattern:
  --  pure Lua and picotool don't allow 0b notation unlike PICO-8, so pass the hex value directly
  --  grid pattern: 0b0101101001011010 -> 0x5A5A
  -- the Stan shirt effect will cause slight eye distraction around the hole patch edges
  --  as the grid pattern won't be moving while the patches are, but this is less worse
  --  than trying to move the pattern by alternating with 0xA5A5 when parallax_offset % 2 == 1
  -- so we kept it like this
  fillp(0x5a5a)
  rectfill(0, 50, 127, 127 - horizon_line_dy, colors.dark_green * 0x10 + colors.black)
  fillp()

  -- put value slightly lower than leaves_row_parallax_speed_min (0.36) since holes are supposed to be yet
  --  a bit farther, so slightly slower in parallax
  local parallax_speed = 0.3
  local parallax_offset = flr(parallax_speed * camera_pos.x)

  -- place holes at different levels for more variety
  local tile_offset_j_cycle = {0, 1, 3}
  local patch_extra_tile_j_cycle = {0, 0, 2}

  for i = 0, 2 do
    -- like clouds, the extra margin beyond screen_width of 128 and the +16/-16 are because sprites
    --  cannot be cut and looped around the screen, and the full background is wider than the screen too
    --  (contains too many elements to be displayed at once)
    -- 8 * tile_size the width of a hole graphics area (the hole sprite and some programmed transition
    --  tiles around)
    -- for 3 times a hole sequence spanning over 8 tiles on X, we get 3 * 8 * 8 = 192
    -- or if we considering offset from screen width: 128 + 8 * tile_size = 192 so perfectly fits
    -- hole areas are placed at different X and follow parallax X
    -- in our case, there is no "space" between what we consider hole areas
    --  so the offset per i is the same as the area width
    local area_width = 8 * tile_size
    local x0 = (80 - parallax_offset) + area_width * i
    -- x0 is actually the left of the hole itself, but the full hole patch with light shaft starts
    --  2 tiles more on the left, so we should work with x0 - 2 * tile_size, which gives the true
    --  offset:
    local modulo_offset = area_width - 2 * tile_size
    x0 = (x0 + modulo_offset) % 192 - modulo_offset
    local y0 = 102
    -- sprite topleft is placed at (x0, y0), and we program graphics around sprite from that position
    -- dark green patch around the hole
    local extra_tile_j = patch_extra_tile_j_cycle[i + 1]

    rectfill(x0, y0 - tile_size, x0 + 4 * tile_size, y0 + (5 + extra_tile_j) * tile_size, colors.dark_green)
    -- transitional zigzagging lines between dark green and black to avoid "squary" patch
    visual_stage.draw_background_forest_bottom_hole_transition_x(x0 - 1, y0, extra_tile_j, -1)
    visual_stage.draw_background_forest_bottom_hole_transition_x(x0 + 4 * tile_size, y0, extra_tile_j, 1)
    visual_stage.draw_background_forest_bottom_hole_transition_y(x0, y0 - tile_size - 1, -1)
    visual_stage.draw_background_forest_bottom_hole_transition_y(x0, y0 + (5 + extra_tile_j) * tile_size, 1)
    -- actual hole sprite
    local hole_y0 = y0 + tile_offset_j_cycle[i + 1] * tile_size
    visual.sprite_data_t.background_forest_bottom_hole:render(vector(x0, hole_y0))
    -- light shaft
    -- located 3 tiles to the left, 2 tiles down of hole -> (-3*8, 2*8) = (-24, 16)
    visual.sprite_data_t.background_forest_bottom_lightshaft:render(vector(x0 - 24, hole_y0 + 16))
  end
end

-- dir_mult: -1 for transition toward left, +1 for transition toward right
function visual_stage.draw_background_forest_bottom_hole_transition_x(x0, y0, extra_tile_j, dir_mult)
  for dy = - tile_size, (5 + extra_tile_j) * tile_size - 1 do
    local y = y0 + dy
    line(x0 + dir_mult * flr(2.5 * (1 + sin(dy/1.7) * sin(dy/1.41))), y, x0, y, colors.dark_green)
  end
end

-- dir_mult: -1 for transition toward up, +1 for transition toward down
function visual_stage.draw_background_forest_bottom_hole_transition_y(x0, y0, dir_mult)
  for dx = 0, 4 * tile_size - 1 do
    local x = x0 + dx
    line(x, y0 + dir_mult * flr(3.7 * (1 + sin(dx/1.65) * sin(dx/1.45))), x, y0, colors.dark_green)
  end
end

function visual_stage.draw_cloud(x, y, dy_list, base_radius, speed)
  -- indigo outline (prefer circfill to circ to avoid gaps
  --  between inside and outline for some values)
  local offset_x = t() * speed
  -- we make clouds cycle horizontally but we don't want to
  --  make them disappear as soon as they exit the screen to the left
  --  so we take a margin of 100px (must be at least cloud width)
  --  before applying modulo (and similarly have a modulo on 128 + 100 + extra margin
  --  where extra margin is to avoid having cloud spawning immediately on screen right
  --  edge)

  -- clouds move to the left
  x0 = (x - offset_x + 100) % 300 - 100

  local dx_rel_to_r_list = {0, 1.5, 3, 4.5}
  local r_mult_list = {0.8, 1.4, 1.1, 0.7}

  -- indigo outline
  for i=1,4 do
    circfill(x0 + flr(dx_rel_to_r_list[i] * base_radius), y + dy_list[i], r_mult_list[i] * base_radius + 1, colors.indigo)
  end

  -- white inside
  for i=1,4 do
    circfill(x0 + flr(dx_rel_to_r_list[i] * base_radius), y + dy_list[i], r_mult_list[i] * base_radius, colors.white)
  end
end

-- TODO VISUAL IMPROVEMENT: improve colors by reusing water_shimmer_color_cycle from visual_titlemenu_addon
local water_reflection_color_cycle = {
  {colors.dark_blue, colors.blue},
  {colors.white,     colors.blue},
  {colors.blue,      colors.dark_blue},
  {colors.blue,      colors.white},
  {colors.dark_blue, colors.blue}
}

function visual_stage.draw_water_reflections(parallax_offset, x, y, period)
  -- animate reflections by switching colors over time
  local ratio = (t() % period) / period
  local step_count = #water_reflection_color_cycle
  -- compute step from ratio (normally ratio should be < 1
  --  just in case, max to step_count)
  local step = min(flr(ratio * step_count) + 1, step_count)
  local draw_colors = water_reflection_color_cycle[step]
  pset((x - parallax_offset) % screen_width, y, draw_colors[1])
  pset((x - parallax_offset + 1) % screen_width, y, draw_colors[2])
end

function visual_stage.draw_tree_row(parallax_offset, y, base_height, row_index0, color)
  for x0 = 0, 127 do
    local x = x0 + parallax_offset
    local height = base_height + flr((3 + 0.5 * row_index0) * (1 + sin(x/(1.7 + 0.2 * row_index0)) * sin(x/1.41)))
    -- draw vertical line from bottom to (variable) top
    line(x0, y, x0, y - height, color)
  end
end

function visual_stage.draw_leaves_row(parallax_offset, y, base_height, row_index0, color)
  for x0 = 0, 127 do
    local x = x0 + parallax_offset
    local height = base_height + flr((4.5 - 0.3 * row_index0) * (1 + sin(x/(41.4 - 9.1 * row_index0))) + 1.8 * sin(x/1.41))
    -- draw vertical line from top to (variable) bottom
    line(x0, y, x0, y + height, color)
  end
end

-- itest stripping end
--#endif

return visual_stage
