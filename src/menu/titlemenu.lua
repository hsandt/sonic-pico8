local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local text_helper = require("engine/ui/text_helper")

local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")

local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

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
  self.menu = menu(self.app--[[, 2]], alignments.left, 3, colors.white--[[skip prev_page_arrow_offset]], visual.sprite_data_t.menu_cursor_shoe, 7)
  self.menu:show_items(titlemenu.items)
end

function titlemenu:on_exit()
end

function titlemenu:update()
  self.menu:update()
end

function titlemenu:render()
  self:draw_background()
  self:draw_title()
  self.menu:draw(55, 101)
end

function titlemenu:draw_background()
  rectfill(0, 0, 128, 128, colors.dark_blue)
  -- water shimmer color cycle (in red and yellow in the original sprite)
  local period = visual.water_shimmer_period
  local ratio = (t() % period) / period
  local step_count = #visual.water_shimmer_color_cycle
  -- compute step from ratio (normally ratio should be < 1
  --  just in case, max to step_count)
  local step = min(flr(ratio * step_count) + 1, step_count)
  local new_colors = visual.water_shimmer_color_cycle[step]
  pal(colors.red, new_colors[1])
  pal(colors.yellow, new_colors[2])
  visual.sprite_data_t.angel_island_bg:render(vector(0, 88))
  pal()
end

function titlemenu:draw_title()
  -- logo should be placed 1 tile to the right, 3 tiles to the bottom,
  --  with its pivot at top-left
  visual.sprite_data_t.title_logo:render(vector(8, 16))
end

return titlemenu
