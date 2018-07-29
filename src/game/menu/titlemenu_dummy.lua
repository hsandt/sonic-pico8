local dummy_gamestate = require("game/application/dummy_gamestate")
local gamestate = require("game/application/gamestate")

local dummy_titlemenu = {}

dummy_titlemenu.state = dummy_gamestate(gamestate.types.titlemenu)

return dummy_titlemenu
