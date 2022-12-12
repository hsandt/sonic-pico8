local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local input = require("engine/input/input")
local postprocess = require("engine/render/postprocess")
local ui_animation = require("engine/ui/ui_animation")

local pcm_data = require("data/pcm_data")
local cinematic_sonic = require("menu/cinematic_sonic")
local splash_screen_phase = require("menu/splash_screen_phase")
local visual = require("resources/visual_common")
-- we should require titlemenu add-on in main

local splash_screen_state = derived_class(gamestate)

splash_screen_state.type = ':splash_screen'


-- derived numeric data

-- generally it's (0, 0) on the spritesheet, but just in case we move it later, check it out
local splash_screen_logo_topleft = visual.sprite_data_t.splash_screen_logo.id_loc:to_topleft_position()

-- nothing in init right now, as content was moved to on_enter
-- it doesn't really matter as you cannot re-enter splash screen state without changing cartridge first
--  (e.g. entering attract mode), so a brand new state would be created anyway, but to be correct semantically,
--  we prefer initalizing all members required for the splash screen animation in on_enter
-- function splash_screen_state:init()
-- end

function splash_screen_state:on_enter()
  self.phase = splash_screen_phase.blank_screen

  -- Commented out, as false is equivalent to nil in bool check
  -- note that this is different from self.phase == splash_screen_phase.fade_out, because it's also true
  --  when player skips splash screen, causing an early fade out before the actual fade_out phase
  -- self.is_fading_out_for_titlemenu = false

  -- only for phase: logo_appears_in_white
  self.logo_first_letter_shown_in_white_index1 = 0  -- invalid in Lua

  -- only for phase: left_speed_lines_fade_out and right_speed_lines_fade_out
  -- reset for each phase, then increment each frame to track how lines should fade and change fill pattern
  self.speed_lines_fade_out_timer = 0

  -- drawable cinematic sonic
  -- sonic pivot is at (8, 8), but also shown at scale 2, so add or remove 2*8=16 to place him completely outside screen on start/end of motion
  self.cinematic_sonic = cinematic_sonic(vector(128 + 16, 64))

  self.postproc = postprocess()

  -- to mimic Sonic 2 intro, fade in and out with shades of blue
  self.postproc.use_blue_tint = true

  -- PCM
  -- self.pcm_sample_length = nil  -- unknown for now, commented out to spare characters
  -- Make sure to start at 1 to avoid pop
  self.pcmpos = 1
  -- Commented out, as false is equivalent to nil in bool check
  -- self.should_play_pcm = false

  self:reload_pcm()

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
  if self.phase < splash_screen_phase.fade_out then
    -- check for any input to skip splash screen and fade out already
    if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
      -- start fade out in parallel with existing animations to keep things smooth
      -- ! do not set self.phase = splash_screen_phase.fade_out because we want other animations to keep
      -- ! running
      -- this, however, will set the independent flag self.is_fading_out_for_titlemenu = true
      -- so we remember not to try to fade out again if we skip just before the actual fade out
      self.app:start_coroutine(self.try_fade_out_and_show_titlemenu_async, self)
    end
  end

  if self.phase == splash_screen_phase.left_speed_lines_fade_out or self.phase == splash_screen_phase.right_speed_lines_fade_out then
    self.speed_lines_fade_out_timer = self.speed_lines_fade_out_timer + 1
  end

  self.cinematic_sonic:update()

  if self.should_play_pcm then
    self:play_pcm()
  end
end

function splash_screen_state:play_splash_screen_sequence_async()
  self.app:yield_delay_s(1)

  self.phase = splash_screen_phase.sonic_moves_left

  -- make Sonic run to the left (default)
  -- sonic pivot is at (8, 8), but also shown at scale 2, so add or remove 2*8=16 to place him completely outside screen on start/end of motion
  ui_animation.move_drawables_on_coord_async("x", {self.cinematic_sonic}, nil, 128 + 16, -16, 15)

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
  self.speed_lines_fade_out_timer = 0

  yield_delay_frames(20)

  self.phase = splash_screen_phase.sonic_moves_right

  -- make Sonic run to the right
  self.cinematic_sonic.is_going_left = false
  ui_animation.move_drawables_on_coord_async("x", {self.cinematic_sonic}, nil, -16, 128 + 16, 15)

  yield_delay_frames(12)

  self.phase = splash_screen_phase.right_speed_lines_fade_out
  self.speed_lines_fade_out_timer = 0

  yield_delay_frames(20)

  self.phase = splash_screen_phase.full_logo

  yield_delay_frames(20)

  -- Start playing PCM (SAGE choir) from here
  -- Don't worry about keeping flag true during fade out, as play_pcm will naturally stop
  -- at the end
  self.should_play_pcm = true

  -- SAGE choir is 1.62s
  -- wait ~1 extra second after it before fading out
  self.app:yield_delay_s(2.6)

  self.phase = splash_screen_phase.fade_out

  self:try_fade_out_and_show_titlemenu_async()
end

function splash_screen_state:try_fade_out_and_show_titlemenu_async()
  -- check flag to avoid doing this twice when player decides to skip splash screen near the end
  --  of animation, so try_fade_out_and_show_titlemenu_async is called once a little early and
  --  once at normal time
  if not self.is_fading_out_for_titlemenu then
    self.is_fading_out_for_titlemenu = true

    self:fade_out_async()

    self.app:yield_delay_s(1)

    -- stop all coroutines before showing titlemenu to avoid, in the case of early splash screen skip,
    --  play_splash_screen_sequence_async doing further processing in the background
    --  (although those would be invisible anyway)
    -- since we do this after the last async call, this very coroutine will still finish properly
    self.app:stop_all_coroutines()
    flow:query_gamestate_type(':titlemenu')
  end
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

--#if debug
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

-- fill pattern of a single speed line
-- we exceptionally don't write 0x since all values are below 10
-- ! contrary to intuition, 0 is color, 1 is transparent !
-- ! you must chain 4 of them to get a full 4x4 fill pattern !
local speed_line_fill_patterns = {
  -- ---- (full line)
  -- 0000
  0,
  -- - -  (half visible line)
  -- 0101
  5,
  -- -    (quarter visible)
  -- 0111
  7,
}

-- number of frames to reach next step in fading out speed line via fill pattern
-- since speed line fade-out lasts 20 frames, and we have 3 (non-empty) patterns + 3rd pattern in gray = 4 phases,
--  for uniform phase duration, 20/4 = 5 is good
local duration_frames_per_single_line_pattern = 5

function splash_screen_state:get_speed_line_fill_phase_index()
  if self.speed_lines_fade_out_timer < duration_frames_per_single_line_pattern then
    -- full line
    return 1
  elseif self.speed_lines_fade_out_timer < 2 * duration_frames_per_single_line_pattern then
    -- half line
    return 2
  elseif self.speed_lines_fade_out_timer < 3 * duration_frames_per_single_line_pattern then
    -- quarter line
    return 3
  else
    -- quarter line in gray
    return 4
  end
end

function splash_screen_state:draw_speed_lines()
  -- always draw speed lines from screen edge to Sonic center
  -- we deduce the back of Sonic from his moving direction

  local line_start_x
  local line_end_x
  local full_fill_pattern
  local color_replacement

  if self.phase == splash_screen_phase.left_speed_lines_fade_out or self.phase == splash_screen_phase.right_speed_lines_fade_out then
    -- we're in fading phase, check the fading pattern we need now
    local fill_phase_index = self:get_speed_line_fill_phase_index()

    -- clamp phase to 3 to get pattern index, since phase 4 reuses pattern 3 but changes color to gray
    local fill_pattern_index = min(fill_phase_index, 3)

    -- if phase 4, prepare color replacement for an even smoother fading just before line disappears completely
    if fill_phase_index >= 4 then
      color_replacement = colors.light_gray
    end

    speed_line_fill_pattern = speed_line_fill_patterns[fill_pattern_index]
  else
    -- Sonic is moving, drawing full lines, so the fill pattern is only to draw only even or odd lines,
    --  but single lines themselves are full (0000 = 0x0)
    speed_line_fill_pattern = 0
  end

  if self.cinematic_sonic.is_going_left then
    -- when going left, fill even lines only (xxxx is the single speed line fill pattern
    --  with 0 for color and 1 for transparent, 1111 is for fully transparent lines)
    --     xxxx
    --     1111
    --     xxxx
    --     1111
    -- to reconstruct this full pattern, we need to always add 0x0f0f for the constant 1111 odd lines,
    --  0x0.8 for transparency on 1, and finally add dynamic patterns xxxx (speed_line_fill_pattern)
    --  twice, each time shifted by 4 * row the offset counted from the bottom (3 and 1) = 12 and 4
    -- CAUTION: + has precedence over << so need brackets!
    -- However, luamin currently supports 5.2 and therefore ignores precedence for new operators like <<
    -- As a result, it is safer to use shl for the time being
    -- Eventually you'll want to integrate 5.4 support which was done in forks:
    -- - https://github.com/FATH-Mechatronics/luamin
    -- - https://github.com/wolfe-labs/luamin-5.4 (forked from FATH-Mechatronics itself)
    -- then you'll be able to use the bracketed << version commented below:
    -- full_fill_pattern = 0x0f0f.8 + (speed_line_fill_pattern << 12) + (speed_line_fill_pattern << 4)
    full_fill_pattern = 0x0f0f.8 + shl(speed_line_fill_pattern, 12) + shl(speed_line_fill_pattern, 4)
  else
    -- when going right, fill odd lines only
    --     1111
    --     xxxx
    --     1111
    --     xxxx
    -- to reconstruct this full pattern, we need to always add 0xf0f0 for the constant 1111 even lines,
    --  0x0.8 for transparency on 1, and finally add dynamic patterns xxxx (speed_line_fill_pattern)
    --  twice, each time shifted by 4 * row the offset counted from the bottom (2 and 0) = 8 and 0
    -- same remark as below, when you switch to luamin 5.4 you can use commented version below:
    -- full_fill_pattern = 0xf0f0.8 + (speed_line_fill_pattern << 8) + speed_line_fill_pattern
    full_fill_pattern = 0xf0f0.8 + shl(speed_line_fill_pattern, 8) + speed_line_fill_pattern
  end

  -- we could check phase:
  -- if splash_screen_phase.sonic_moves_left <= self.phase and self.phase <= splash_screen_phase.left_speed_lines_fade_out
  -- but since we've done this already before calling draw_speed_lines, we only need to distinguish left and right,
  --  so checking is_going_left is simpler
  if self.cinematic_sonic.is_going_left then
    -- draw between Sonic and screen right
    line_start_x = self.cinematic_sonic.position.x
    line_end_x = 127
  else
    -- draw between screen left and Sonic
    line_start_x = 0
    line_end_x = self.cinematic_sonic.position.x - 1
  end

  -- set fill pattern to draw alternative lines
  fillp(full_fill_pattern)

  if color_replacement then
    pal(colors.blue, color_replacement)
  end

  -- cover y from highest to lowest possible position that needs to be drawn,
  --  but depending on the pattern, the top-most or bottom-most line may be empty
  rectfill(line_start_x, 64-16, line_end_x, 64+15, colors.blue)

  if color_replacement then
    pal()
  end

  -- reset fill pattern or the title menu will be messed up!
  fillp()
end


-- PCM: play digitized audio samples already stored in memory
-- Thanks to IMLXH (also carlc27843 and czarlo)
-- https://www.lexaloffle.com/bbs/?tid=45013
-- https://colab.research.google.com/drive/1HyiciemxfCDS9DxE98UCtNXas5TrM-5e?usp=sharing
-- Modifications by hsandt:
-- - prefer buffer length of stat(109) - stat(108) following
--   https://pico-8.fandom.com/wiki/Stat#{108%E2%80%A6109}_5kHz_PCM_Audio
-- - start pcmpos at 1 instead of 0 to avoid pop at the beginning (see init)
-- - no need to support backward play
-- - store pcm sample length in first two bytes, so read sample bytes from 0x8002

-- reload PCM: unlike the forum examples, we stored the PCM as GFX data, converted from
--  PCM string at offline time (see main_generate_gfx_sage_choir_pcm_data),
--  so we must now copy gfx data from the cartridge containing it to extra general memory
function splash_screen_state:reload_pcm()
  -- PICO-8 has extra general memory to use at address 0x8000 with a size up to 0x8000
  --  which is what we need for the huge PCM data coming from GFX and therefore up to
  --  0x2000 (vs standard general memory which contains up to 0x1b00 only)
  --  which is unlockable using `poke(0x5f36, 16)` before v0.2.4, so unlock it now.
  -- From v0.2.4, it is unlocked by default
  poke(0x5f36, 16)

  -- Copy full gfx sections of data_stage1_10.p8 and data_stage1_11.p8
  -- concatenated into current extra general memory (see install_data_cartridges_with_merging.sh)
  -- to reconstruct the full audio pcm sample into current memory, ready to be read.
  -- This includes the pcm sample length header
  reload(0x8000, 0x0, 0x2000, "data_stage1_10.p8")
  reload(0xa000, 0x0, 0x2000, "data_stage1_11.p8")

  -- We stored the PCM sample length in the first two bytes, so read it back,
  --  now copied at 0x8000
  self.pcm_sample_length = peek2(0x8000)
end

-- play PCM: must be called after reload_pcm
function splash_screen_state:play_pcm()
  if self.pcmpos >= self.pcm_sample_length then
    return nil
  end

  local l = stat(109) - stat(108)
  l = min(l, self.pcm_sample_length - self.pcmpos)

  -- make sure to read actual sample bytes after the stored sample length,
  --  so starting 0x8002
  serial(0x808, 0x8002 + self.pcmpos, l)
  self.pcmpos = self.pcmpos + l
end

-- export

return splash_screen_state
