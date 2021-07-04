-- game application for state: stage
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local stage_state = require("ingame/stage_state")

local picosonic_app_attract_mode = derived_class(picosonic_app_base)

function picosonic_app_attract_mode:instantiate_gamestates() -- override (mandatory)
  return {stage_state()}
end

function picosonic_app_attract_mode:on_post_start() -- override (optional)
  picosonic_app_base.on_post_start(self)

  menuitem(5, "back to title", function()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_titlemenu')
  end)
end

return picosonic_app_attract_mode