require("constants")
require("debug")
require("flow")
require("math")
require("playercharacter")
stage = require("stage")
flow = require("flow")

local stage_state = stage.state

flow:add_gamestate(stage_state)
flow:_change_gamestate(stage_state)

stage_state.player_character.move_intention = vector(1, -1)
-- won't work unless i have input hijack
stage_state:update()

local expected_position = stage.data.spawn_location:to_center_position() +
  vector(1, -1) * stage_state.player_character.debug_move_speed * delta_time
printh(stage_state.player_character.position:_tostring())
printh(expected_position:_tostring())
