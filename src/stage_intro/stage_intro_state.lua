local gamestate = require("engine/application/gamestate")

local stage_intro_state = derived_class(gamestate)

stage_intro_state.type = ':stage_intro'

function stage_intro_state:on_enter()
  -- immediately load stage for now, as this is just a stub for the future stage intro
  load('picosonic_ingame.p8')
end

return stage_intro_state
