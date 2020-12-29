-- game application for state: stage_intro
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local stage_intro_state = require("stage_intro/stage_intro_state")

local picosonic_app_stage_intro = derived_class(picosonic_app_base)

function picosonic_app_stage_intro:instantiate_gamestates() -- override
  return {stage_intro_state()}
end

return picosonic_app_stage_intro
