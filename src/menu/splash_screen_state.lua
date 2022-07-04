local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local postprocess = require("engine/render/postprocess")
local ui_animation = require("engine/ui/ui_animation")

local cinematic_sonic = require("menu/cinematic_sonic")
local splash_screen_phase = require("menu/splash_screen_phase")
local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

local splash_screen_state = derived_class(gamestate)

splash_screen_state.type = ':splash_screen'


-- derived numeric data

-- generally it's (0, 0) on the spritesheet, but just in case we move it later, check it out
local splash_screen_logo_topleft = visual.sprite_data_t.splash_screen_logo.id_loc:to_topleft_position()


function splash_screen_state:init()
  self.phase = splash_screen_phase.blank_screen
  -- only for phase: logo_appears_in_white
  self.logo_first_letter_shown_in_white_index1 = 0  -- invalid in Lua

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

  self.phase = splash_screen_phase.sonic_moves_left

  -- make Sonic run to the left (default)
  -- sonic pivot is at (8, 8), but also shown at scale 2, so add or remove 2*8=16 to place him completely outside screen on start/end of motion
  ui_animation.move_drawables_on_coord_async("x", {self.cinematic_sonic}, {0}, 128 + 16, -16, 15)

  self.phase = splash_screen_phase.logo_appears_in_white
  self.logo_first_letter_shown_in_white_index1 = 4  -- start with E

  yield_delay_frames(3)
  self.logo_first_letter_shown_in_white_index1 = 3  -- show G

  yield_delay_frames(3)
  self.logo_first_letter_shown_in_white_index1 = 2  -- show A

  yield_delay_frames(3)
  self.logo_first_letter_shown_in_white_index1 = 1  -- show S

  yield_delay_frames(3)

  self.phase = splash_screen_phase.left_speed_lines_fade_out

  yield_delay_frames(18)

  self.phase = splash_screen_phase.sonic_moves_right

  -- make Sonic run to the right
  self.cinematic_sonic.is_going_left = false
  ui_animation.move_drawables_on_coord_async("x", {self.cinematic_sonic}, {0}, -16, 128 + 16, 15)

  yield_delay_frames(12)

  self.phase = splash_screen_phase.right_speed_lines_fade_out

  yield_delay_frames(18)

  self.phase = splash_screen_phase.full_logo

  self.app:yield_delay_s(1)

  self.phase = splash_screen_phase.fade_out

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

  -- draw speed lines from phase where Sonic moves in one direction until phase where lines in that direction
  --  fade out; also make sure that Sonic (center) has entered screen so we don't draw unexpected lines
  --  when there should be none
  if splash_screen_phase.sonic_moves_left <= self.phase and self.phase <= splash_screen_phase.left_speed_lines_fade_out and self.cinematic_sonic.position.x <= 128 or
      splash_screen_phase.sonic_moves_right <= self.phase and self.phase <= splash_screen_phase.right_speed_lines_fade_out and self.cinematic_sonic.position.x > 0 then
    self:draw_speed_lines()
  end

  self:draw_splash_screen_logo()

  -- draw Sonic when inside or partially inside screen
  if -16 < self.cinematic_sonic.position.x and self.cinematic_sonic.position.x < 128 + 16 then
    self.cinematic_sonic:draw()
  end

  self.postproc:apply()

--#ifn release
  api.print("phase: "..self.phase, 1, 1, colors.black)
--#endif
end

local splash_screen_logo_size = vector(91, 32)
local splash_screen_logo_letter_start_x_offsets = {
  0,  -- S
  21, -- A
  49, -- G
  71, -- E
}

function splash_screen_state:draw_splash_screen_logo()
  if self.phase == splash_screen_phase.logo_appears_in_white then
    local letter_start_x_offset = splash_screen_logo_letter_start_x_offsets[self.logo_first_letter_shown_in_white_index1]
    local splash_screen_logo_first_shown_letter_topleft = splash_screen_logo_topleft + vector(letter_start_x_offset, 0)

    -- draw letters from first one shown to last one, with appropriate offset
    palt(colors.pink, true)
    pal({
      [colors.light_gray] = colors.white,
      [colors.blue] = colors.white,
      })
    sspr(splash_screen_logo_first_shown_letter_topleft.x, splash_screen_logo_first_shown_letter_topleft.y,
      splash_screen_logo_size.x - letter_start_x_offset, splash_screen_logo_size.y,
      letter_start_x_offset + 19, 47)  -- mind 1st empty row of pixels in SAGE sprite, so 47 instead of 48
    pal()
  elseif splash_screen_phase.left_speed_lines_fade_out <= self.phase and self.phase <= splash_screen_phase.sonic_moves_right then
    -- draw every other horizontal line: even lines only
    -- over 32px (Sonic height is 16px, at scale 2: 32px)
    -- this must match draw_speed_lines for y coordinates when self.cinematic_sonic.is_going_left is true,
    --  so it really looks like the left speed lines are leaving marks to shape half of the logo
    -- since we are working in relative coordinates here, we start at the first even line in absolute coord
    --  which is in fact y=64-16, but on the logo sprite, it's the first row with actual non-transparent pixels
    --  at row offset 1 (the top row is empty) -> we still have 16 lines
    -- remember to draw lines by by one (source height = 1), at the appropriate offset on both source and
    --  destination
    palt(colors.pink, true)
    for offset_y=1,31,2 do
      sspr(splash_screen_logo_topleft.x, splash_screen_logo_topleft.y + offset_y,
        splash_screen_logo_size.x, 1,
        19, 47 + offset_y)  -- mind 1st empty row of pixels in SAGE sprite, so 47 instead of 48
    end
    palt()
  elseif splash_screen_phase.right_speed_lines_fade_out <= self.phase then
    -- as soon as right lines start fading out, we must draw full logo to as right lines will stop covering it
    visual.sprite_data_t.splash_screen_logo:render(vector(19, 79))
  end
end

function splash_screen_state:draw_speed_lines()
  -- always draw speed lines from screen edge to Sonic center
  -- we deduce the back of Sonic from his moving direction

  local line_start_x
  local line_end_x
  local line_fill_pattern

  -- we could check phase:
  -- if splash_screen_phase.sonic_moves_left <= self.phase and self.phase <= splash_screen_phase.left_speed_lines_fade_out
  -- but since we've done this already before calling draw_speed_lines, we only need to distinguish left and right,
  --  so checking is_going_left is simpler
  if self.cinematic_sonic.is_going_left then
    -- draw between Sonic and screen right
    line_start_x = self.cinematic_sonic.position.x
    line_end_x = 127
    -- fill pattern for even lines only (0 for color, 1 for transparent)
    --     0000
    --     1111
    --     0000
    --     1111
    -- + 0x0.8 for transparency
    line_fill_pattern = 0x0f0f.8
  else
    -- draw between screen left and Sonic
    line_start_x = 0
    line_end_x = self.cinematic_sonic.position.x - 1
    -- fill pattern for odd lines only (0 for color, 1 for transparent)
    --     1111
    --     0000
    --     1111
    --     0000
    -- + 0x0.8 for transparency
    line_fill_pattern = 0xf0f0.8
  end

  -- set fill pattern to draw alternative lines
  fillp(line_fill_pattern)

  -- cover y from highest to lowest possible position that needs to be drawn,
  --  but depending on the pattern, the top-most or bottom-most line may be empty
  rectfill(line_start_x, 64-16, line_end_x, 64+15, colors.blue)
end

-- export

return splash_screen_state
