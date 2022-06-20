local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")

local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

local splash_screen_state = derived_class(gamestate)

splash_screen_state.type = ':splash_screen'

-- parameters data

function splash_screen_state:init()
  self.show_logo = false
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
end

function splash_screen_state:play_splash_screen_sequence_async()
  self.app:yield_delay_s(1)

  -- show SAGE logo
  self.show_logo = true

  self.app:yield_delay_s(1)

  flow:query_gamestate_type(':titlemenu')
end

function splash_screen_state:render()
  cls(colors.white)

  if self.show_logo then
    self:draw_splash_screen_logo()
  end
end

function splash_screen_state:draw_splash_screen_logo()
  visual.sprite_data_t.splash_screen_logo:render(vector(19, 79))
end

-- export

return splash_screen_state
