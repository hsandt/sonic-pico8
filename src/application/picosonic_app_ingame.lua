-- game application for state: stage
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local stage_state = require("ingame/stage_state")

local picosonic_app_ingame = derived_class(picosonic_app_base)

function picosonic_app_ingame:instantiate_gamestates() -- override
  return {stage_state()}
end

return picosonic_app_ingame
