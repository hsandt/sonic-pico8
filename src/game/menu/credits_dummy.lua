local dummy_gamestate = require("game/application/dummy_gamestate")
local gamestate = require("game/application/gamestate")

local dummy_credits = {}

dummy_credits.state = dummy_gamestate(gamestate.types.credits)

return dummy_credits
