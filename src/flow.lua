local flow = {}

-- enums
local gamestate_type = {
 titlemenu = 1,
 credits = 2,
 stage = 3,
}

-- parameters
gamestates = {}

-- state vars
current_gamestate = nil

-- add a gamestate
function add_gamestate(gamestate)
 assert(gamestate)
 gamestates[gamestate.state_type] = gamestate
end

-- enter a gamestate
function change_state(gamestate_type)
 current_gamestate = gamestates[gamestate_type]
 assert(current_gamestate)
 current_gamestate.on_enter()
end

-- export
flow.gamestate_type = gamestate_type
return flow
