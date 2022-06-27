local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local postprocess = require("engine/render/postprocess")
local ui_animation = require("engine/ui/ui_animation")

local cinematic_sonic = require("menu/cinematic_sonic")
local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

local splash_screen_state = derived_class(gamestate)

splash_screen_state.type = ':splash_screen'

-- parameters data

function splash_screen_state:init()
  self.show_logo = false

  -- drawable cinematic sonic
  -- sonic pivot is at (8, 8), but also shown at scale 2, so add or remove 2*8=16 to place him completely outside screen on start/end of motion
  self.cinematic_sonic = cinematic_sonic(vector(128 + 16, 64))

  self.postproc = postprocess()

  -- to mimic Sonic 2 intro, fade in and out with sahdes of blue
  self.postproc.use_blue_tint = true
end

function splash_screen_state:on_enter()
  -- splash screen data is stored in extra gfx_splash_screen.p8 at edit time (not exported),
  --  and merged into data_stage1_01.p8 (overwriting the tiles gfx, unused at runtime), so instead of:
  -- reload(0x0, 0x0, 0x2000, "gfx_splash_screen.p8")
  --  we must reload full spritesheet from data_stage1_01.p8
  -- see install_data_cartridges_with_merging.sh
  -- however, remember to first backup builtin GFX so we can show the titlemenu later immediately
  --  (we could also put splash screen GFX in builtin data, and reload titlemenu GFX from another cartridge,
  --  but I would still recommend pre-loading titlemenu GFX in advance just to avoid the rotating cart animation
  --  played on first reload (even when using patched pico8, first load/reload seems slower when passing
  --  no file name as my patch is incomplete; and passing picosonic_titlemenu does nothing, as if copying from
  --  current memory; it is absurd as we can later reload start cinematic data instantly, but we have to get
  --  around this))
  -- we cannot backup the full builtin spritesheet, which takes 0x2000, whereas general memory has 0x1B00
  -- fortunately, splash screen GFX only occupy the top half of the spritesheet,
  --  so we can just backup the top half, and only reload the top half of splash screen GFX,
  --  so we only need 0x1000 bytes and never touch the bottom half

  -- backup titlemenu GFX into general memory
  memcpy(0x4300, 0x0, 0x1000)

  -- reload splash screen GFX
  reload(0x0, 0x0, 0x1000, "data_stage1_01.p8")

  -- play main sequence
  self.app:start_coroutine(self.play_splash_screen_sequence_async, self)
end

function splash_screen_state:on_exit()
end

function splash_screen_state:update()
  self.cinematic_sonic:update()
end

function splash_screen_state:play_splash_screen_sequence_async()
  self.app:yield_delay_s(1)

  -- make Sonic run to the left (default)
  -- sonic pivot is at (8, 8), but also shown at scale 2, so add or remove 2*8=16 to place him completely outside screen on start/end of motion
  ui_animation.move_drawables_on_coord_async("x", {self.cinematic_sonic}, {0}, 128 + 16, -16, 15)

  yield_delay_frames(30)

  -- make Sonic run to the right
  self.cinematic_sonic.is_going_left = false
  ui_animation.move_drawables_on_coord_async("x", {self.cinematic_sonic}, {0}, -16, 128 + 16, 15)

  -- show SAGE logo
  self.show_logo = true

  self.app:yield_delay_s(1)

  self:fade_out_async()

  self.app:yield_delay_s(1)

  flow:query_gamestate_type(':titlemenu')
end

function splash_screen_state:fade_out_async()
  -- fade out
  for i = 1, 5 do
    self.postproc.darkness = i
    yield_delay_frames(6)
  end
end

function splash_screen_state:render()
  cls(colors.white)

  if self.show_logo then
    self:draw_splash_screen_logo()
  end

  -- draw speed lines when Sonic has entered screen indeed for given move direction
  if self.cinematic_sonic.is_going_left and self.cinematic_sonic.position.x <= 128 or
      not self.cinematic_sonic.is_going_left and self.cinematic_sonic.position.x > 0 then
    self:draw_speed_lines()
  end

  -- draw Sonic when inside or partially inside screen
  if -16 < self.cinematic_sonic.position.x and self.cinematic_sonic.position.x < 128 + 16 then
    self.cinematic_sonic:draw()
  end

  self.postproc:apply()
end

function splash_screen_state:draw_splash_screen_logo()
  visual.sprite_data_t.splash_screen_logo:render(vector(19, 79))
end

function splash_screen_state:draw_speed_lines()
  -- always draw speed lines from screen edge to Sonic center
  -- we deduce the back of Sonic from his moving direction

  local line_start_x
  local line_end_x

  if self.cinematic_sonic.is_going_left then
    -- draw every other horizontal line: even lines only
    line_start_x = self.cinematic_sonic.position.x
    line_end_x = 127
  else
    line_start_x = 0
    line_end_x = self.cinematic_sonic.position.x - 1
  end

  -- draw every other horizontal line: even lines only
  -- over 32px (Sonic height is 16px, at scale 2: 32px)
  for y=64-16,64+14,2 do
    line(line_start_x, y, line_end_x, y, colors.blue)
  end
end

-- export

return splash_screen_state
