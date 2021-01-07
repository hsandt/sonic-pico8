-- game application for state: stage
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local stage_state = require("ingame/stage_state")

local picosonic_app_ingame = derived_class(picosonic_app_base)

function picosonic_app_ingame:instantiate_gamestates() -- override (mandatory)
  return {stage_state()}
end

function picosonic_app_ingame:on_post_start() -- override (optional)
  picosonic_app_base.on_post_start(self)

  menuitem(3, "warp to start", function()
    assert(flow.curr_state.type == ':stage')
    flow.curr_state:store_picked_emerald_data()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_ingame')
  end)

  menuitem(4, "retry from zero", function()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_ingame')
  end)

  menuitem(5, "back to title", function()
    -- prefer passing basename for compatibility with .p8.png
    load('picosonic_titlemenu')
  end)
end

return picosonic_app_ingame
