require("bustedhelper")
require("game/itests/itestplayercharacter")
local debug = require("engine/debug/debug")
local gameapp = require("game/application/gameapp")

debug.active_categories["itest"] = true

describe('itest player character', function ()

  it('should succeed', function ()
    itest_manager:init_game_and_start('character debug moves to right')
    local finished = false
    while integration_test_runner.current_state == test_states.running do
      integration_test_runner:update_game_and_test()
    end
    assert.are_equal(test_states.success, integration_test_runner.current_state)
  end)
end)
