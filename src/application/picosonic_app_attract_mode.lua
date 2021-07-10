-- game application for state: stage
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local input = require("engine/input/input")
local postprocess = require("engine/render/postprocess")

local stage_state = require("ingame/stage_state")

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
end

function picosonic_app_attract_mode:on_update() -- override (optional)
  -- handle input: press any button to leave attract mode (avoids entering pause menu)
  -- usually inputs are handled in gamestate, but for same reason as self.postproc we do it here

  if input:is_just_pressed(button_ids.o) or input:is_just_pressed(button_ids.x) then
    self:exit_attract_mode()
  end
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
  for i = 0, 5 do
    self.postproc.darkness = i
    yield_delay_frames(6)
  end

  -- prefer passing basename for compatibility with .p8.png
  load('picosonic_titlemenu')
end

return picosonic_app_attract_mode
