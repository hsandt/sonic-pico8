local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local input = require("engine/input/input")
local text_helper = require("engine/ui/text_helper")

local credits_data = require("data/credits_data")

local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

local credits = derived_class(gamestate)

credits.type = ':credits'

-- parameters data
local copyright_text = text_helper.wwrap("this is a fan game distributed for free on itch.io and sfghq (sage 2021) and is not endorsed by sega games co. ltd, which owns the sonic the hedgehog trademark and copyrights.", 31)

function credits:init()
  -- current scrolling
  self.current_scrolling = 0
end

function credits:on_enter()
  music(-1)
end

function credits:on_exit()
end

function credits:update()
  if input:is_down(button_ids.up) then
    self:scroll(-tuned("scroll_speed", 64) * delta_time60)
  elseif input:is_down(button_ids.down) then
    self:scroll(tuned("scroll_speed", 64) * delta_time60)
  elseif input:is_just_pressed(button_ids.x) then
    flow:query_gamestate_type(':titlemenu')
  end
end

function credits:scroll(delta)
  self.current_scrolling = mid(self.current_scrolling + delta, 0, tuned("max clamping", 242))
end

function credits:render()
  -- reset camera so background is not affected by scrolling
  camera()

  -- uniform background color
  rectfill(0, 0, 127, 127, colors.dark_blue)

  -- background texture is made of repeated "Sonic" text offset every other line as in Sonic 2 options menu,
  --  predefined in the built-in titlemenu cart map
  -- it uses pink background
  set_unique_transparency(colors.pink)
  -- it is drawn in dark green so title logo can make it transparent, but in reality it should be black
  pal(colors.dark_green, colors.black)
  -- add small padding of 1px from screen edges
  map(0, 0, 1, 1, 16, 16)
  -- reset palette changes
  pal()

  -- apply scrolling to content
  camera(0, self.current_scrolling)

  self:draw_credits_text()

  -- input hints

  -- reset camera again so hints are not affected by scrolling, but still displayed on top
  camera()

  -- background
  local hint_bg_width = tuned("w", 128)
  local hint_bg_height = tuned("h", 15)
  rectfill(0, 128 - hint_bg_height, hint_bg_width - 1, 127, colors.black)

  -- text
  text_helper.print_aligned("##u##d - scroll\n##x - back", 2, 128 - hint_bg_height + 2, alignments.left, colors.white, colors.black)
end

function credits:draw_credits_text()
  local text_color = colors.white
  local outline_color = colors.black
  local role_margin = tuned("role margin", 2)
  local paragraph_margin = tuned("paragraph margin", 6)

  -- top
  local y = tuned("top", 20)

  text_helper.print_aligned("pico sonic - credits", 64, y, alignments.horizontal_center, text_color, outline_color)
  y = y + character_height + paragraph_margin + 2

  for role_name_pair in all(credits_data.role_name_pairs) do
    local role_text = role_name_pair[1]
    local name_text = role_name_pair[2]

    text_helper.print_aligned(role_text, 64, y, alignments.horizontal_center, text_color, outline_color)
    y = y + text_helper.compute_text_height(role_text) + role_margin

    text_helper.print_aligned(name_text, 64, y, alignments.horizontal_center, text_color, outline_color)
    y = y + text_helper.compute_text_height(name_text) + paragraph_margin
  end

  text_helper.print_aligned(copyright_text, 64, y, alignments.horizontal_center, text_color, outline_color)
  y = y + text_helper.compute_text_height(copyright_text) + paragraph_margin

  text_helper.print_aligned("komehara.itch.io/pico-sonic", 64, y, alignments.horizontal_center, text_color, outline_color)
  y = y + character_height + paragraph_margin

  text_helper.print_aligned("https://sonicfangameshq.com/\nforums/showcase/pico-sonic.985", 64, y, alignments.horizontal_center, text_color, outline_color)
end

-- export

return credits
