local logger = require("engine/debug/logger")

local flow = singleton {
 -- parameters
 gamestates = {},

 -- state vars
 current_gamestate = nil,
 next_gamestate = nil,
}

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
 assert(self.current_gamestate == nil or self.current_gamestate.type ~= gamestate_type, "flow:query_gamestate_type: cannot query the current gamestate type "..gamestate_type.." again")
 self.next_gamestate = self.gamestates[gamestate_type]
 assert(self.next_gamestate ~= nil, "[flow] gamestate type "..gamestate_type.." has not been added to the flow gamestates")
end

-- check if a new gamestate was queried, and enter it if so
function flow:_check_next_gamestate(gamestate_type)
 if self.next_gamestate then
  self:_change_gamestate(self.next_gamestate)
 end
end

-- enter a new gamestate
function flow:_change_gamestate(new_gamestate)
  assert(new_gamestate ~= nil, "[flow] cannot change to nil gamestate")
  if self.current_gamestate then
    self.current_gamestate:on_exit()
  end
  self.current_gamestate = new_gamestate
  new_gamestate:on_enter()
  self.next_gamestate = nil  -- clear any gamestate query
  log("changed gamestate to "..self.current_gamestate.type, "flow")
end

-- immediately enter a new gamestate without calling transition functions (for use in itests)
function flow:change_gamestate_silent(new_gamestate)
  assert(new_gamestate ~= nil, "[flow] cannot change to nil gamestate")
  self.current_gamestate = new_gamestate
  self.next_gamestate = nil  -- clear any gamestate query
end

-- export
return flow
