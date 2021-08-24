local input = require("engine/input/input")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local sprite_object = require("engine/render/sprite_object")
local text_helper = require("engine/ui/text_helper")

local emerald_cinematic = require("menu/emerald_cinematic")
local menu_item = require("menu/menu_item")
local menu = require("menu/menu_with_sfx")
local emerald_common = require("render/emerald_common")
local audio = require("resources/audio")
local visual = require("resources/visual_common")  -- we should require visual_titlemenu add-on in main
local ui_animation = require("ui/ui_animation")

local titlemenu = derived_class(gamestate)

titlemenu.type = ':titlemenu'

-- parameters data

-- sequence of menu items to display, with their target states
local menu_item_params = {
  {"start", function(app)
    local curr_stage_state = flow.curr_state
    assert(curr_stage_state.type == titlemenu.type)
    curr_stage_state:play_start_cinematic()
  end},
  {"credits", function(app)
    flow:query_gamestate_type(':credits')
  end},
}

-- parameters:
-- items                        {menu_item}    sequence of menu items that the menu should display

-- state:
-- title_logo_drawable          sprite_object   drawable for title logo sprite motion interpolation
-- angel_island_bg_drawable     sprite_object   drawable for angel island background drawable
-- cinematic_drawables          {sprite_object} all other drawables for the start cinematic
-- cinematic_emeralds_on_circle {int}           number of all emeralds rotating on a circle/ellipse
-- menu                         menu            title menu showing items (only created when it must be shown)
-- frames_before_showing_menu   int             number of frames before showing menu. Ignored if 0.
-- should_start_attract_mode    bool            should we enter attract mode now?
-- is_playing_start_cinematic   bool            are we playing the start cinematic?

-- there are more members during the start cinematic, but they will be created when it starts
function titlemenu:init()
  -- sequence of menu items to display, with their target states
  -- this could be static, but defining in init allows us to avoid
  --  outer scope definition, so we don't need to declare local menu_item
  --  at source top for unity build
  self.items = transform(menu_item_params, unpacking(menu_item))
  self.title_logo_drawable = sprite_object(visual.sprite_data_t.title_logo)
  self.angel_island_bg_drawable = sprite_object(visual.sprite_data_t.angel_island_bg)
  self.cinematic_drawables = {}
  self.cinematic_emeralds_on_circle = {}

  -- self.menu = nil  -- commented out to spare characters

  -- defined in on_enter anyway, but we still define it to allow utests to handle that
  --  without simulating on_enter (and titlemenu cartridge has enough space)
  self.frames_before_showing_menu = 0
  self.should_start_attract_mode = false
  self.is_playing_start_cinematic = false
end

function titlemenu:on_enter()
  self.app:start_coroutine(self.play_opening_music_async, self)

  -- show menu after short intro of 2 columns
  -- we assume play_opening_music_async was started at the same time
  -- title bgm is at SPD 12 so that makes
  --   12 SPD * 4 frames/SPD/column * 2 columns = 96 frames
  self.frames_before_showing_menu = 96
  self.should_start_attract_mode = false
  self.is_playing_start_cinematic = false

  -- logo should be initially placed 1 tile to the right, 3 tiles to the bottom,
  --  with its pivot at top-left
  self.title_logo_drawable.position = vector(8, 16)
  self.angel_island_bg_drawable.position = vector(0, 88)
end

function titlemenu:play_opening_music_async()
  -- start title BGM
  music(audio.music_ids.title)

  -- fade out current bgm during the last half-measure (we have a decreasing volume
  --   in the music itself but there is still a gap between volume 1 and 0 in PICO-8
  --   and using a custom instrument just to decrease volume is cumbersome, hence the
  --   additional fade-out by code)
  -- the fast piano track ends with SFX 16 after 4 patterns (repeating one of the SFX once)
  -- and 2 columns, over 1 columns, which makes the fade out start at:
  --   12 SPD * 4 frames/SPD/column * (4 patterns * 4 columns + 2 columns) = 864 frames
  -- and lasts:
  --   12 SPD * 4 frames/SPD/column * 1 column = 48 frames = 48 * 1000 / 60 = 800 ms
  yield_delay_frames(864)
  music(-1, 800)

  -- wait for music fade out to finish (48 frames), then wait a little more before
  --   starting attract mode (1s = 60 frames), similarly to Sonic 3
  yield_delay_frames(108)

  self.should_start_attract_mode = true
end

function titlemenu:show_menu()
  self.menu = menu(self.app--[[, 2]], alignments.left, 3, colors.white--[[skip prev_page_arrow_offset]], visual.sprite_data_t.menu_cursor_shoe, 7)
  self.menu:show_items(self.items)
end

-- this is called when entering credits
function titlemenu:on_exit()
  -- clear menu completely (will call GC, but fine)
  self.menu = nil

  clear_table(self.cinematic_drawables)
  clear_table(self.cinematic_emeralds_on_circle)

  -- stop all coroutines, this is important to prevent play_opening_music_async from continuing in the background
  --  while reading credits, and fading out music earlier than expected after coming back to title
  self.app:stop_all_coroutines()
end

function titlemenu:update()
  if self.is_playing_start_cinematic then
    return
  end

  if self.menu then
    self.menu:update()

    -- attract mode countdown
    if self.should_start_attract_mode then
      self:start_attract_mode()
    end
  else
    -- menu not shown yet, check for immediate show input vs normal countdown

    if input:is_just_pressed(button_ids.o) then
      -- show menu immediately
      self.frames_before_showing_menu = 0
    else
      -- decrement countdown
      self.frames_before_showing_menu = self.frames_before_showing_menu - 1
    end

    if self.frames_before_showing_menu <= 0 then
      self:show_menu()
    end
  end
end

function titlemenu:start_attract_mode()
    load('picosonic_attract_mode')
end

function titlemenu:render()
  self:draw_background()
  self:draw_title()
  self:draw_version()

  if self.menu then
    self.menu:draw(55, 101)
  end

  for drawable in all(self.cinematic_drawables) do
    drawable:draw()
  end

  for num in all(self.cinematic_emeralds_on_circle) do
    -- inspired by stage_clear_state:draw_emeralds, adding rotation and elliptical effect
    local radius = visual.start_cinematic_emerald_circle_radius
    local period = visual.start_cinematic_emerald_rotation_period
    -- rotation center at (64, 68) (slightly below screen center)
    -- emeralds rotate clockwise, so negative factor for t()
    local draw_position = vector(64 + radius * cos(0.25 - (num - 1) / 8 - t() / period),
      68 + radius * sin(0.25 - (num - 1) / 8 - t() / period))
    -- draw at normal brightness
    emerald_common.draw(num, draw_position)
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
  swap_colors({colors.red, colors.yellow}, new_colors)
  self.angel_island_bg_drawable:draw()
  pal()
end

function titlemenu:draw_title()
  self.title_logo_drawable:draw()
end

function titlemenu:draw_version()
  -- preprocess can now replace $variables so build_single_cartridge.sh
  --  will just pass the version string to the builder so it replaces $version here
  text_helper.print_aligned("V$version", 126, 2, alignments.right, colors.white, colors.black)
end

function titlemenu:play_start_cinematic()
  -- hide (actually destroy) menu
  self.menu = nil

  self.is_playing_start_cinematic = true
  self.app:start_coroutine(self.play_start_cinematic_async, self)
end

function titlemenu:play_start_cinematic_async()
  -- multiply number of frames of 100ms in Aseprite animation by 6 to get frames of (1/60)s

  -- run in parallel with emeralds entering screen, so start new coroutine from this coroutine
  self.app:start_coroutine(self.move_title_logo_out_async, self)

  yield_delay_frames(5)

  -- setup all emeralds to enter on screen and start rotating
  local emeralds = {}
  for i = 1, 8 do
    local emerald = emerald_cinematic(i, vector(0, 92))
    add(emeralds, emerald)                  -- for easier local tracking
    add(self.cinematic_drawables, emerald)  -- for drawing
    self.app:start_coroutine(self.emerald_enter_async, self, emeralds[i])
  end

  yield_delay_frames(36)

  -- after a short delay (first two emeralds entered), start moving island down
  --  until it leaves screen, to simulate camera moving upward toward the sky
  self.app:start_coroutine(self.move_island_down_async, self)

  yield_delay_frames(100)

  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_stage_intro')
end

function titlemenu:move_title_logo_out_async()
  -- move title logo up until it exists screen, and hide it
  ui_animation.move_drawables_on_coord_async("y", {self.title_logo_drawable}, {0}, 16, -80, 42)
  self.title_logo_drawable.visible = false
end

function titlemenu:emerald_enter_async(emerald)
  -- emerald enters from bottom-left to circle top, with delay depending on emerald
  -- (last emerald enters last)
  -- 3 100ms-frames of lag in Aseprite, so 18 frames between successive emeralds
  yield_delay_frames(18 * (emerald.number - 1))
  ui_animation.move_drawables_async({emerald}, vector(0, 92), vector(55, 52), 18)

  -- from here, remove emerald from normal drawables and attach it to the circle to let it
  --  be drawn with rotating circle/ellipse formula instead
  del(self.cinematic_drawables, emerald)
  add(self.cinematic_emeralds_on_circle, emerald.number)
end

function titlemenu:move_island_down_async()
  -- move island down until it exists screen, and hide it
  ui_animation.move_drawables_on_coord_async("y", {self.angel_island_bg_drawable}, {0}, 88, 88+36, 54)
  -- self.title_logo_drawable.visible = false
end

return titlemenu
