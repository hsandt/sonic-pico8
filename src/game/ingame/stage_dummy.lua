local dummy_gamestate = require("game/application/dummy_gamestate")
local gamestate = require("game/application/gamestate")

local dummy_stage = {}

dummy_stage.state = dummy_gamestate(gamestate.types.stage)

return dummy_stage
