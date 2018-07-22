require("engine/test/integrationtest")
require("game/itests/itest$itest")


function _init()
  integration_test_runner:init_game_and_start(itest)
end

function _update60()
  integration_test_runner:update_game_and_test()
end

function _draw()
  integration_test_runner:draw_game_and_test()
end
