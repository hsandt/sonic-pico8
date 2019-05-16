require("engine/core/class")
--#if log
local logging = require("engine/debug/logging")
--#endif

-- abstract gamestate singleton (no actual class, make your own as long as it has member/interface below)
-- type        string       gamestate type name
-- on_enter    function()   gamestate enter callback
-- on_exit     function()   gamestate exit callback
-- update      function()   gamestate update callback
-- render      function()   gamestate render callback

-- flow singleton
-- state vars
-- curr_state   gamestates     current gamestate
-- next_state   gamestates     next gamestate, nil if no transition expected
local flow = singleton(function (self)
  -- parameters
  self.gamestates = {}

  -- state vars
  self.curr_state = nil
  self.next_state = nil
end)

function flow:update()
  self:_check_next_state()
  if self.curr_state then
    self.curr_state:update()
  end
end

function flow:render()
  if self.curr_state then
    self.curr_state:render()
  end
end

-- add a gamestate
-- currently, we are not asserting if gamestate has already been added,
--  as there are some places in utests that add the same gamestate twice,
--  but it would definitely be cleaner
function flow:add_gamestate(gamestate)
  assert(gamestate ~= nil, "flow:add_gamestate: passed gamestate is nil")
  self.gamestates[gamestate.type] = gamestate
end

-- query a new gamestate
function flow:query_gamestate_type(gamestate_type)
  assert(gamestate_type ~= nil, "flow:query_gamestate_type: passed gamestate_type is nil")
  assert(self.curr_state == nil or self.curr_state.type ~= gamestate_type, "flow:query_gamestate_type: cannot query the current gamestate type '"..gamestate_type.."' itself")
  self.next_state = self.gamestates[gamestate_type]
  assert(self.next_state ~= nil, "flow:query_gamestate_type: gamestate type '"..gamestate_type.."' has not been added to the flow gamestates")
end

-- check if a new gamestate was queried, and enter it if so
function flow:_check_next_state(gamestate_type)
  if self.next_state then
    self:_change_state(self.next_state)
  end
end

-- enter a new gamestate
function flow:_change_state(new_gamestate)
  assert(new_gamestate ~= nil, "flow:_change_state: cannot change to nil gamestate")
  if self.curr_state then
    self.curr_state:on_exit()
  end
  self.curr_state = new_gamestate
  new_gamestate:on_enter()
  self.next_state = nil  -- clear any gamestate query
end

--#if itest
-- check if a new gamestate was queried, and enter it if so (convenient for itests)
function flow:change_gamestate_by_type(gamestate_type)
  assert(self.gamestates[gamestate_type] ~= nil, "flow:change_gamestate_by_type: gamestate type '"..gamestate_type.."' has not been added to the flow gamestates")
  self:_change_state(self.gamestates[gamestate_type])
end
--#endif

-- export
return flow
