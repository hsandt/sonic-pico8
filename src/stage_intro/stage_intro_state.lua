local gamestate = require("engine/application/gamestate")
local postprocess = require("engine/render/postprocess")
local label = require("engine/ui/label")
local overlay = require("engine/ui/overlay")
local rectangle = require("engine/ui/rectangle")

local stage_data = require("data/stage_data")
local stage_intro_data = require("data/stage_intro_data")
local ui_animation = require("ui/ui_animation")

local stage_intro_state = derived_class(gamestate)

stage_intro_state.type = ':stage_intro'

function stage_intro_state:init()
  -- data
  self.curr_stage_data = stage_data.for_stage[1]

  -- render
  self.overlay = overlay()
  self.postproc = postprocess()
end

function stage_intro_state:on_enter()
  self.app:start_coroutine(self.show_stage_splash_async, self)
end

-- never called, we directly load ingame cartridge
--[[
function stage_intro_state:on_exit()
  -- clear all coroutines
  self.app:stop_all_coroutines()

  -- clear object state vars
  self.overlay:clear_drawables()

  -- reinit camera offset for other states
  camera()
end
--]]

function stage_intro_state:render()
  self:render_overlay()
  self.postproc:apply()
end

-- render the title overlay with a fixed ui camera
function stage_intro_state:render_overlay()
  camera()
  self.overlay:draw()
end

function stage_intro_state:show_stage_splash_async()
  -- fade in
  for i = 5, 0, -1 do
    self.postproc.darkness = i
    yield_delay(7)
  end

  self.app:yield_delay_s(stage_intro_data.show_stage_splash_delay)

  -- FIXME: draw iteration order not guaranteed, pico-sonic may be hidden "below" banner

  -- init position y is -height so it starts just at the screen top edge
  local banner = rectangle(vector(9, -106), 32, 106, colors.red)
  self.overlay:add_drawable("banner", banner)

  -- banner text accompanies text, and ends at y = 89, so starts at y = 89 - 106 = -17
  local banner_text = label("pico\nsonic", vector(16, -17), colors.white)
  self.overlay:add_drawable("banner_text", banner_text)

  -- make banner enter from the top
  ui_animation.move_drawables_on_coord_async("y", {banner, banner_text}, {0, 89}, -106, 0, 9)

  local zone_rectangle = rectangle(vector(128, 45), 47, 3, colors.black)
  self.overlay:add_drawable("zone_rect", zone_rectangle)

  local zone_label = label(self.curr_stage_data.title, vector(129, 43), colors.white)
  self.overlay:add_drawable("zone", zone_label)

  -- make text enter from the right
  ui_animation.move_drawables_on_coord_async("x", {zone_rectangle, zone_label}, {0, 1}, 128, 41, 14)

  -- keep zone displayed for a moment
  yield_delay(102)

  -- make banner exit to the top
  ui_animation.move_drawables_on_coord_async("y", {banner, banner_text}, {0, 89}, 0, -106, 8)

  -- make text exit to the right
  ui_animation.move_drawables_on_coord_async("x", {zone_rectangle, zone_label}, {0, 1}, 41, 128, 14)

  self.overlay:remove_drawable("banner")
  self.overlay:remove_drawable("banner_text")
  self.overlay:remove_drawable("zone")

  -- splash is over, load ingame cartridge and give control to player
  load('picosonic_ingame.p8')
end

return stage_intro_state
