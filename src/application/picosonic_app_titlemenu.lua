-- game application for states: titlemenu, credits
-- used by main and itest_main

-- this really only defines used gamestates
--  and wouldn't be necessary if we injected gamestates from main scripts

local picosonic_app_base = require("application/picosonic_app_base")

local titlemenu = require("menu/titlemenu")
local credits = require("menu/credits")

local picosonic_app_ingame = derived_class(picosonic_app_base)

function picosonic_app_ingame:instantiate_gamestates() -- override
  return {titlemenu(), credits()}
end

return picosonic_app_ingame
