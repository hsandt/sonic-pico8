require("engine/core/class")

-- an intermediate module that breaks dependencies by providing the wanted
--  version of each gamestate for the current build
-- each module is a lua gamestate module, either the authentic or a dummy one
local gamestate_proxy = singleton(function (self)
  self._state_modules = {}
  self._state_modules.titlemenu = nil
  self._state_modules.credits = nil
  self._state_modules.stage = nil
end)

-- load a particular version of the gamestate: standard or dummy
-- in pico8 builds, pass nothing, as the preprocess step will determine what is required
-- in busted tests, pass the list of gamestates to use, by name (e.g. {"titlemenu", "credits"})
function gamestate_proxy:require_gamestates(active_gamestates)

--[[#pico8
  self._state_modules.titlemenu = require("game/menu/titlemenu$titlemenu_ver")
  self._state_modules.credits = require("game/menu/credits$credits_ver")
  self._state_modules.stage = require("game/ingame/stage$stage_ver")
--#pico8]]

--#ifn pico8
  require("engine/test/assertions")  -- for "contains"

  -- busted runs directly on the scripts, so there is no need to preprocess
  -- to exclude unused gamestates and require minimal files as in the built .p8
  -- instead, we need to require_gamestates with the list of active gamestates
  -- for pico8 versions, active_gamestates can be nil, it won't be used anyway
  local dirs = {
    titlemenu = "menu",
    credits = "menu",
    stage = "ingame"
  }

  local versions = {}
  for gamestate in all({"titlemenu", "credits", "stage"}) do
    if contains(active_gamestates, gamestate) then
      version_suffix = ""
    else
      version_suffix = "_dummy"
    end
    self._state_modules[gamestate] = require("game/"..dirs[gamestate].."/"..gamestate..version_suffix)
  end
--#endif

end

-- return the gamestate with given name to use for that build
-- normally, this is the gamestate in the module of the same name,
-- but in minimal builds, unused gamestates are replaced
-- with a lightweight dummy state
function gamestate_proxy:get(module_name)
  assert(type(module_name) == "string")
  assert(self._state_modules[module_name] ~= nil, "gamestate_proxy:get: self._state_modules['"..module_name.."'] is nil, make sure you have called gamestate_proxy:require_gamestates before")
  assert(type(self._state_modules[module_name]) == "table" and self._state_modules[module_name].state, "gamestate_proxy:get: self._state_modules[module_name] is not a function with a 'state' member")
  return self._state_modules[module_name].state
end

return gamestate_proxy
