-- modules
flow = require("flow")
titlemenu = require("titlemenu")


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 flow.add_gamestate(titlemenu.state)
 flow.change_state(titlemenu.state.state_type)
end

function _update()
 current_gamestate.update()
end

function _draw()
 current_gamestate.render()
end
