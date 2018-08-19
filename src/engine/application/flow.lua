require("engine/core/class")
--#if log
local logging = require("engine/debug/logging")
--#endif

-- gamestate singleton interface
-- type        string       gamestate type name
-- on_enter    function()   gamestate enter callback
-- on_exit     function()   gamestate exit callback
-- update      function()   gamestate update callback
-- render      function()   gamestate render callback

local flow = singleton(function (self)
  -- parameters
  self.gamestates = {}

  -- state vars
  self.current_gamestate = nil
  self.next_gamestate = nil
end)

--#if log
function flow:_tostring()
  return "[flow]"
end
--#endif

function flow:update()
  self:_check_next_gamestate()
  if self.current_gamestate then
    self.current_gamestate:update()
  end
end

function flow:render()
  if self.current_gamestate then
    self.current_gamestate:render()
  end
end

-- add a gamestate
function flow:add_gamestate(gamestate)
  assert(gamestate ~= nil, "flow:add_gamestate: passed gamestate is nil")
  self.gamestates[gamestate.type] = gamestate
end

-- query a new gamestate
function flow:query_gamestate_type(gamestate_type)
  assert(gamestate_type ~= nil, "flow:query_gamestate_type: passed gamestate_type is nil")
  assert(self.current_gamestate == nil or self.current_gamestate.type ~= gamestate_type, "flow:query_gamestate_type: cannot query the current gamestate type '"..gamestate_type.."' itself")
  self.next_gamestate = self.gamestates[gamestate_type]
  assert(self.next_gamestate ~= nil, "flow:query_gamestate_type: gamestate type '"..gamestate_type.."' has not been added to the flow gamestates")
end

-- check if a new gamestate was queried, and enter it if so
function flow:_check_next_gamestate(gamestate_type)
  if self.next_gamestate then
    self:_change_gamestate(self.next_gamestate)
  end
end

-- enter a new gamestate
function flow:_change_gamestate(new_gamestate)
  assert(new_gamestate ~= nil, "flow:_change_gamestate: cannot change to nil gamestate")
  if self.current_gamestate then
    self.current_gamestate:on_exit()
  end
  self.current_gamestate = new_gamestate
  new_gamestate:on_enter()
  self.next_gamestate = nil  -- clear any gamestate query
  log("changed gamestate to "..self.current_gamestate.type, "flow")
end

--#if test
-- check if a new gamestate was queried, and enter it if so (convenient for itests)
function flow:change_gamestate_by_type(gamestate_type)
  assert(self.gamestates[gamestate_type] ~= nil, "flow:change_gamestate_by_type: gamestate type '"..gamestate_type.."' has not been added to the flow gamestates")
  self:_change_gamestate(self.gamestates[gamestate_type])
end
--#endif

-- export
return flow
