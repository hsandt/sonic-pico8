require("engine/application/flow")
local gamestate = require("engine/application/gamestate")


local credits = derived_class(gamestate)

credits.type = ':credits'

-- function credits:on_enter()
-- end

-- function credits:on_exit()
-- end

-- function credits:update()
-- end

function credits:render()
  color(colors.white)
  api.print("credits state", 4*11, 6*12)
end

-- export

return credits
