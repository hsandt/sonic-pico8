require("engine/core/class")
require("engine/render/color")

-- class for dummy gamestates
-- you don't need to derive it, just create an instance of dummy_gamestate
-- passing the appropriate type to create one
local dummy_gamestate = new_class()

function dummy_gamestate:_init(type)
  self.type = type
end

function dummy_gamestate:on_enter()
end

function dummy_gamestate:on_exit()
end

function dummy_gamestate:update()
end

function dummy_gamestate:render()
  color(colors.white)
  api.print(self.type.." state", 4*11, 6*12)
end

return dummy_gamestate
