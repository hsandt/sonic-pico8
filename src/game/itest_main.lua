require("engine/test/integrationtest")
require("game/itests/itest$itest")


function _init()
  -- temporary way to run single itest
  -- when itest files start having multiple tests, you'll need a name-based search test running
  for itest_name, itest in pairs(itest_manager.itests) do
    itest_manager:init_game_and_start_by_name(itest_name)
    break
  end
end

function _update60()
  integration_test_runner:update_game_and_test()
end

function _draw()
  integration_test_runner:draw_game_and_test()
end
