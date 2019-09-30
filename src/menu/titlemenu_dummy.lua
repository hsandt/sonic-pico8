local dummy_gamestate = require("application/dummy_gamestate")
local gamestate = require("application/gamestate")

local dummy_titlemenu = {}

dummy_titlemenu.state = dummy_gamestate(gamestate.types.titlemenu)

return dummy_titlemenu
