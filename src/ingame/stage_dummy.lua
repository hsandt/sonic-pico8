local dummy_gamestate = require("application/dummy_gamestate")
local gamestate = require("application/gamestate")

local dummy_stage = {}

dummy_stage.state = dummy_gamestate(gamestate.types.stage)

return dummy_stage
