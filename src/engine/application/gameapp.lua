local flow = require("engine/application/flow")
local class = require("engine/core/class")
local input = require("engine/input/input")

-- main class for the game, taking care of the overall init, update, render
-- usage: derive from gameapp and override on_start, on_reset, on_update, on_render
-- in the main _init, set the initial_gamestate and call the app start()
-- in the main _update(60), call the app update()
-- in the main _draw, call the app render()
-- in integration tests, call the app reset() before starting a new itest
local gameapp = new_class()

-- constructor: members are only config values for init_modules
-- managers           {<start, update, render>}  sequence of managers to update and render in the loop
-- initial_gamestate  string|nil                 key of the initial first gamestate to enter (nil if unset)
--                                               set it manually before calling start(),
--                                               and make sure you called register_gamestates with a matching state
function gameapp:_init()
  self.managers = {}
  self.initial_gamestate = nil
end

-- register the managers you want to update and render
-- they may be managers provided by the engine like visual_logger and profiler,
--   or custom managers, as long as they provide the methods `update` and `render`
-- in this engine, we prefer injection to having a configuration with many flags
--   to enable/disable certain managers.
-- we can still override on_update/on_render for custom effects, but prefer handling managers when possible
function gameapp:register_managers(...)
  for manager in all({...}) do
    add(self.managers, manager)
  end
end

-- override to add gamestates to flow singleton
function gameapp:register_gamestates()
  -- ex:
  -- flow:add_gamestate(...)
end

-- unlike _init, init_modules is called later, after finishing the configuration
-- in pico-8, it must be called in the global _init function
function gameapp:start()
  self:register_gamestates()

  -- REFACTOR: consider making flow a very generic manager, that knows the initial gamestate
  -- and is only added if you want
  assert(self.initial_gamestate ~= nil, "gameapp:start: gameapp.initial_gamestate is not set")
  flow:query_gamestate_type(self.initial_gamestate)
  for manager in all(self.managers) do
    manager:start()
  end
  self:on_start()
end

-- override to initialize custom managers
function gameapp:on_start() -- virtual
end

--#if itest
function gameapp:reset()
  flow:init()
  self:on_reset()
end

-- override to call :init on your custom managers, or to reset anything set up in
-- in gameapp:start/on_start, really
function gameapp:on_reset() -- virtual
end
--#endif

function gameapp:update()
  input:process_players_inputs()
  for manager in all(self.managers) do
    manager:update()
  end
  flow:update()
  self:on_update()
end

-- override to add custom update behavior
function gameapp:on_update() -- virtual
end

function gameapp:draw()
  cls()
  flow:render()
  for manager in all(self.managers) do
    manager:render()
  end
  self:on_render()
end

-- override to add custom render behavior
function gameapp:on_render() -- virtual
end

return gameapp
