require("engine/core/fun_helper")
local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local text_helper = require("engine/ui/text_helper")

local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")

local visual = require("resources/visual_common")  -- just to use titlemenu add-on
require("resources/visual_titlemenu_addon")

local titlemenu = derived_class(gamestate)

titlemenu.type = ':titlemenu'

-- parameters data

-- sequence of menu items to display, with their target states
titlemenu.items = transform({
    {"start", function(app)
      load('picosonic_ingame.p8')
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
  -- logo should be placed 1 tile to the right, 3 tiles to the bottom,
  --  with its pivot at top-left
  visual.sprite_data_t.title_logo:render(vector(8, 24))
end

return titlemenu
