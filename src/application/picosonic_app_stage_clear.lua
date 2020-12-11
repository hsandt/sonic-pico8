-- game application for state: stage_clear
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local stage_clear_state = require("stage_clear/stage_clear_state")

local picosonic_app_stage_clear = derived_class(picosonic_app_base)

function picosonic_app_stage_clear:instantiate_gamestates() -- override
  return {stage_clear_state()}
end

return picosonic_app_stage_clear
