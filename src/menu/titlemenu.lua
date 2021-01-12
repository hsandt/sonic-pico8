local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local text_helper = require("engine/ui/text_helper")

local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")

local audio = require("resources/audio")
local visual = require("resources/visual_common")  -- we should require titlemenu add-on in main

local titlemenu = derived_class(gamestate)

titlemenu.type = ':titlemenu'

-- parameters data

-- sequence of menu items to display, with their target states
local menu_item_params = {
  {"start", function(app)
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_stage_intro')
  end},
  {"credits", function(app)
    flow:query_gamestate_type(':credits')
  end},
}

-- attributes:
-- menu     menu     title menu showing items (only created when it must be shown)

function titlemenu:init()
  -- sequence of menu items to display, with their target states
  -- this could be static, but defining in init allows us to avoid
  --  outer scope definition, so we don't need to declare local menu_item
  --  at source top for unity build
  self.items = transform(menu_item_params, unpacking(menu_item))
end

function titlemenu:on_enter()
  self.app:start_coroutine(self.opening_sequence_async, self)
end

function titlemenu:opening_sequence_async()
  -- start title BGM
  music(audio.music_ids.title)

  -- show menu after short intro of 2 columns
  -- title bgm is at SPD 12 so that makes
  --   12 SPD * 4 frames/SPD/column * 2 columns = 96 frames
  yield_delay(96)
  self:show_menu()

  -- fade out current bgm during the last half-measure (we have a decreasing volume
  --   in the music itself but there is still a gap between volume 1 and 0 in PICO-8
  --   and using a custom instrument just to decrease volume is cumbersome, hence the
  --   additional fade-out by code)
  -- the fast piano track ends with SFX 16 after 4 patterns (repeating one of the SFX once)
  -- and 2 columns, over 1 columns, which makes the fade out start at:
  --   12 SPD * 4 frames/SPD/column * (4 patterns * 4 columns + 2 columns) = 864 frames
  -- and lasts:
  --   12 SPD * 4 frames/SPD/column * 1 column = 48 frames = 48 * 1000 / 60 = 800 ms
  -- we've already waited 96 frames so only wait 864 - 96 = 768 frames now
  yield_delay(768)
  music(-1, 800)
end

function titlemenu:show_menu()
  self.menu = menu(self.app--[[, 2]], alignments.left, 3, colors.white--[[skip prev_page_arrow_offset]], visual.sprite_data_t.menu_cursor_shoe, 7)
  self.menu:show_items(self.items)
end

function titlemenu:on_exit()
  -- clear menu completely (will call GC, but fine)
  self.menu = nil

  -- stop all coroutines, this is important to prevent opening_sequence_async from continuing in the background
  --  while reading credits, and fading out music earlier than expected after coming back to title
  self.app:stop_all_coroutines()
end

function titlemenu:update()
  if self.menu then
    self.menu:update()
  end
end

function titlemenu:render()
  self:draw_background()
  self:draw_title()
  self:draw_version()

  if self.menu then
    self.menu:draw(55, 101)
  end
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

function titlemenu:draw_version()
  -- PICO-8 cannot access data/version.txt and we don't want to preprocess substitute some $version
  -- tag in build script just for this, so we exceptionally hardcode version number
  -- coords correspond to top-right corner with a small margin
  text_helper.print_aligned("V5.2", 126, 2, alignments.right, colors.white, colors.black)
end

return titlemenu
