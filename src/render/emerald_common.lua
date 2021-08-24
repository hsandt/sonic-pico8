-- common functionality for emerald rendering between titlemenu, ingame and stage clear
-- with the exception of emerald silhouette, only used ingame
--  (but if titlemenu has a few extra characters it's OK)

local visual = require("resources/visual_common")

local emerald_common = {}

-- static (as used by emerald.draw and emerald_fx:render)
-- set the color palette swap from red to emerald matching passed number
-- don't forget to reset with pal() manually after drawing
-- optional brightness can be passed, to convert light to white (level 1 and 2),
-- dark to light (level 1) and dark to white (level 2). Default 0 preserves brightness.
function emerald_common.set_color_palette(number, brightness)
  brightness = brightness or 0

  -- swap colors based on emerald number
  -- note that the reference emerald in the Red emerald,
  --  which uses white (invariant), red (light color) and dark_purple (dark color)
  --  so we must replace the last two with our custom colors
  local light_color, dark_color = unpack(visual.emerald_colors[number])

  local brightness_color_swap = {
    -- original colors : red, dark_purple
    {light_color,  dark_color},
    {colors.white, light_color},
    {colors.white, colors.white},
  }

  -- brightness starts at 0, index starts at 1, so add 1
  assert(0 <= brightness and brightness <= 2, "invalid brightness: "..brightness)
  -- local new_colors = brightness_color_swap[brightness + 1]
  swap_colors({colors.red, colors.dark_purple}, brightness_color_swap[brightness + 1])

  -- pal(colors.red, brightness_color_swap[brightness + 1][1])
  -- pal(colors.dark_purple, brightness_color_swap[brightness + 1][2])
end

-- static (as used by render_hud even without a proper emerald object)
-- draw emerald with correct color based on number, at given position
-- can be used for HUD and stage
-- optional brightness affects palette, see set_color_palette
function emerald_common.draw(number, position, brightness)
  if number >= 0 then
    emerald_common.set_color_palette(number, brightness)

    -- pass center of tile, so emerald is represented with pivot at the center
    visual.sprite_data_t.emerald:render(position)
    pal()
  else
    -- negative number (typically -1) for empty emerald,
    --  draw emerald silhouette instead (HUD only)
    -- ! emerald_silhouette is defined in visual_ingame_addon,
    -- ! so this will crash if called in titlemenu code, make sure to pass number >= 0!
    visual.sprite_data_t.emerald_silhouette:render(position)
  end
end

return emerald_common
