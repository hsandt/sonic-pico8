-- game application for state: stage
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local input = require("engine/input/input")
local postprocess = require("engine/render/postprocess")

local stage_state = require("ingame/stage_state")

-- define everything Sonic must do during the attract mode here
-- it's not 100% correct to do it in main because this relies on flow having entered stage state
--  but since it's the initial state, it should be entered on frame 1 anyway
local function attract_mode_scenario_async()
  -- wait for 1 frame so flow finishes loading the initial state: stage
  yield()

  assert(flow.curr_state, "flow has no current state yet")
  assert(flow.curr_state.type == ':stage')

  local pc = flow.curr_state.player_char
  assert(pc)

  pc.control_mode = control_modes.puppet

  -- normally we should set pc.control_mode to control_modes.puppet
  --  but since we're already stripping player_char:handle_input from #ifn attract_mode,
  --  we don't need to do anything

  -- now do the demonstration!
  -- this is similar to our itest DSL, except the DSL is too expensive in a cartridge
  --  (when combined with ingame code which includes background rendering unlike our itests)
  --  so we just manually set character intention and wait between actions with yield_delay

  yield_delay_frames(42)
  pc.move_intention = vector(1, 0)
  yield_delay_frames(318)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(4)
  pc.hold_jump_intention = false
  yield_delay_frames(10)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(16)
  pc.move_intention = vector(1, 0)
  yield_delay_frames(26)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(14)
  pc.hold_jump_intention = false
  yield_delay_frames(90)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(6)
  pc.move_intention = vector(0, 0)
  pc.hold_jump_intention = false
  yield_delay_frames(6)
  pc.move_intention = vector(-1, 0)
  yield_delay_frames(4)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(36)
  pc.move_intention = vector(1, 0)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(6)
  pc.hold_jump_intention = false
  yield_delay_frames(6)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(8)
  pc.move_intention = vector(1, 0)
  yield_delay_frames(12)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(16)
  pc.move_intention = vector(1, 0)
  yield_delay_frames(10)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(10)
  pc.move_intention = vector(0, 0)
  pc.hold_jump_intention = false
  yield_delay_frames(21)
  pc.move_intention = vector(-1, 0)
  yield_delay_frames(14)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(16)
  pc.move_intention = vector(1, 0)
  yield_delay_frames(4)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(14)
  pc.move_intention = vector(0, 1)
  yield_delay_frames(14)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(5)
  pc.hold_jump_intention = false
  yield_delay_frames(3)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(5)
  pc.hold_jump_intention = false
  yield_delay_frames(2)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(5)
  pc.hold_jump_intention = false
  yield_delay_frames(2)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(5)
  pc.hold_jump_intention = false
  yield_delay_frames(2)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(5)
  pc.hold_jump_intention = false
  yield_delay_frames(3)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(4)
  pc.hold_jump_intention = false
  yield_delay_frames(4)
  pc.jump_intention = true
  pc.hold_jump_intention = true
  yield_delay_frames(4)
  pc.hold_jump_intention = false
  yield_delay_frames(2)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(21)
  pc.move_intention = vector(1, 0)
  yield_delay_frames(94)
  pc.move_intention = vector(0, 1)
  yield_delay_frames(4)
  pc.move_intention = vector(0, 0)
  yield_delay_frames(24)

  -- if you want to record a demo yourself:
  -- 0. comment/remove any previous input order you don't need in the list above
  -- 1. uncomment the block of code below
  -- 2. build and run 'attract_mode' cartridge with 'recorder' config
  -- 3. it will automatically play the section above, then give control to human
  -- 4. from here, play what you want to demonstrate in attract mode
  -- 5. close the game and open (on Linux) .lexaloffle/pico-8/carts/picosonic/v[version]_recorder/picosonic_attract_mode_log.p8l
  -- 6. remove first line with "START RECORDING HUMAN INPUT" then all line prefixes "[recorder] "
  -- 7. copy-paste the resulting lines just above this comment block

  -- pc.control_mode = control_modes.human
  -- log(total_frames..": START RECORDING HUMAN INPUT", "recorder")
  -- total_frames = 0  -- reset total frames as we want relative delays since last record

  -- end demo, exit attract mode with fade out (if not already due to input)
  app:exit_attract_mode()
end

local picosonic_app_attract_mode = derived_class(picosonic_app_base)

function picosonic_app_attract_mode:instantiate_gamestates() -- override (mandatory)
  return {stage_state()}
end

function picosonic_app_attract_mode:on_post_start() -- override (optional)
  picosonic_app_base.on_post_start(self)

  -- postprocess for fade-out
  -- usually this is done in gamestate, but attract mode uses the same stage_state
  --  as ingame, so we'd need #if attract_mode to distinguish behavior, and it's simpler to
  --  put dedicated behavior here
  self.postproc = postprocess()
  -- self.is_exiting = false  -- commented out to spare characters, as nil is equivalent

  menuitem(5, "back to title", function()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_titlemenu')
  end)

  -- start attract mode scenario
  self:start_coroutine(attract_mode_scenario_async)
end

function picosonic_app_attract_mode:on_update() -- override (optional)
  -- handle input: press any button to leave attract mode (avoids entering pause menu)
  -- usually inputs are handled in gamestate, but for same reason as self.postproc we do it here

  if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
    self:exit_attract_mode()
  end

--#if recorder
  -- increment total frames for timed recording
  total_frames = total_frames + 1
--#endif
end

function picosonic_app_attract_mode:on_render() -- override (render)
  self.postproc:apply()
end

function picosonic_app_attract_mode:exit_attract_mode()
  if not self.is_exiting then
    self.is_exiting = true
    self:start_coroutine(self.exit_attract_mode_async, self)
  end
end

function picosonic_app_attract_mode:exit_attract_mode_async()
  -- fade out
  for i = 1, 5 do
    self.postproc.darkness = i
    yield_delay_frames(6)
  end

  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_titlemenu')
end

return picosonic_app_attract_mode
