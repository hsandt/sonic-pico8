require("engine/core/fun_helper")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")

local titlemenu = derived_class(gamestate)

titlemenu.type = ':titlemenu'

-- parameters data

-- sequence of menu items to display, with their target states
titlemenu.items = transform({
    {"start", function(app)
      flow:query_gamestate_type(':stage')
    end},
    {"credits", function(app)
      flow:query_gamestate_type(':credits')
    end},
  }, unpacking(menu_item))

function titlemenu:on_enter()
  self.menu = menu(self.app, 2, alignments.horizontal_center, colors.white)
  self.menu:show_items(titlemenu.items)
end

function titlemenu:on_exit()
end

function titlemenu:update()
  self.menu:update()
end

function titlemenu:render()
  self:draw_title()
  self.menu:draw(screen_width / 2, 72)
end

function titlemenu:draw_title()
  local y = 14
  ui.print_centered("* pico-sonic *", 64, y, colors.white)
  y = y + 8
  ui.print_centered("by leyn", 64, y, colors.white)
end

return titlemenu
