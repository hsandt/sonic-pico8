local dummy_gamestate = require("application/dummy_gamestate")
local gamestate = require("application/gamestate")

local dummy_credits = {}

dummy_credits.state = dummy_gamestate(gamestate.types.credits)

return dummy_credits
