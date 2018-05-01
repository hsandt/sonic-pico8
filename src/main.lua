-- modules
flow = require("flow")

gamestates = {}
current_gamestate = nil

function add_gamestate(gamestate)
 assert(gamestate)
 gamestates[gamestate.state_type] = gamestate
end

function change_state(gamestate_type)
 current_gamestate = gamestates[gamestate_type]
 current_gamestate.on_enter()
end

-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 add_gamestate(flow.titlemenu_state)
 change_state(flow.gamestate_type.titlemenu)
end

function _update()
 current_gamestate.update()
end

function _draw()
 current_gamestate.render()
end
