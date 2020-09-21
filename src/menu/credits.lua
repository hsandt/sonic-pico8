require("engine/core/fun_helper")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")

local credits = derived_class(gamestate)

credits.type = ':credits'

-- parameters data

local copyright_text = wwrap("this is a fan game distributed for free and is not endorsed by sega games co. ltd, which owns the sonic the hedgehog trademark and copyrights.", 31)

-- sequence of menu items to display, with their target states
credits.items = transform({
    {"back", function(app)
      flow:query_gamestate_type(':titlemenu')
    end},
  }, unpacking(menu_item))

function credits:on_enter()
  self.menu = menu(self.app, 2, alignments.horizontal_center, colors.white)
  self.menu:show_items(credits.items)
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

  ui.print_aligned("pico-sonic - credits", 64, y, alignments.horizontal_center, text_color)
  y = y + line_dy + paragraph_margin + 2

  api.print("sonic team", margin_x, y, text_color)
  ui.print_aligned("original games", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy + paragraph_margin

  api.print("leyn", margin_x, y, text_color)
  ui.print_aligned("programming", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy
  ui.print_aligned("sprites and sfx", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy
  ui.print_aligned("bgm adjustments", 127 - margin_x, y, alignments.right, text_color)
  y = y + line_dy + paragraph_margin

  api.print("original 8-bit bgm by danooct1\n  thx to midi2pico by gamax92", margin_x, y, text_color)
  y = y + 2 * line_dy + paragraph_margin

  api.print("gameplay resources\n  - sonic physics guide\n  - tas videos game resources", margin_x, y, text_color)
  y = y + 3 * line_dy + paragraph_margin

  api.print(copyright_text, margin_x, y, text_color)
end

-- export

return credits
