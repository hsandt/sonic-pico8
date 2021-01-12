local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local text_helper = require("engine/ui/text_helper")

local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")

local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

local credits = derived_class(gamestate)

credits.type = ':credits'

-- parameters data

local menu_item_params = {
  {"back", function(app)
    flow:query_gamestate_type(':titlemenu')
  end}
}

local copyright_text = wwrap("this is a fan game distributed for free and is not endorsed by sega games co. ltd, which owns the sonic the hedgehog trademark and copyrights.", 31)

function credits:init()
  -- sequence of menu items to display, with their target states
  -- this could be static, but defining in init allows us to avoid
  --  outer scope definition, so we don't need to declare local menu_item
  --  at source top for unity build
  self.items = transform(menu_item_params, unpacking(menu_item))
end

function credits:on_enter()
  music(-1)

  self.menu = menu(self.app--[[, 2]], alignments.left, 3, colors.white--[[skip prev_page_arrow_offset]], visual.sprite_data_t.menu_cursor, 7)
  self.menu:show_items(self.items)
end

function credits:on_exit()
end

function credits:update()
  self.menu:update()
end

function credits:render()
  self:draw_credits_text()
  self.menu:draw(screen_width / 2, 120)
end

function credits:draw_credits_text()
  rectfill(0, 0, 127, 127, colors.dark_blue)

  local text_color = colors.white
  local margin_x = 2
  local line_dy = character_height
  local paragraph_margin = 4

  -- top
  local y = 2

  text_helper.print_aligned("pico sonic - credits", 64, y, alignments.horizontal_center, text_color)
  y = y + line_dy + paragraph_margin + 2

  api.print("sonic team", margin_x, y, text_color)
  text_helper.print_aligned("original games", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy + paragraph_margin

  api.print("leyn", margin_x, y, text_color)
  text_helper.print_aligned("programming", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy
  text_helper.print_aligned("sprites and sfx", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy
  text_helper.print_aligned("bgm adjustments", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy + paragraph_margin

  api.print("original 8-bit bgm by danooct1\n  thx to midi2pico by gamax92", margin_x, y, text_color)
  y = y + 2 * line_dy + paragraph_margin

  api.print("gameplay resources\n  - sonic physics guide\n  - tas videos game resources", margin_x, y, text_color)
  y = y + 3 * line_dy + paragraph_margin

  api.print(copyright_text, margin_x, y, text_color)
end

-- export

return credits
