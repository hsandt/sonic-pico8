picotest = require("picotest")
stage = require("stage")
flow = require("flow")

function test_stage(desc,it)

  local stage_state = stage.state

  desc('stage.state.type', function ()
    it('should be gamestate_type.stage', function ()
      return stage_state.type == gamestate_type.stage
    end)
  end)

  desc('stage.state.spawn_player_character', function ()
    stage_state:spawn_player_character()
    it('should spawn the player character', function ()
      return stage_state.player_character ~= nil
    end)
    it('...at the stage spawn location', function ()
      return stage_state.player_character ~= nil and stage_state.player_character.position == stage.data.spawn_location:to_position()
    end)
  end)

  desc('enter stage state', function ()
    flow:add_gamestate(stage_state)
    flow:_change_gamestate(stage_state)

    desc('[after enter stage state] stage.stage.player_character', function ()
      it('should not be nil', function ()
        return stage_state.player_character ~= nil
      end)
      it('should be located at stage spawn location', function ()
        return stage_state.player_character ~= nil and stage_state.player_character.position == stage.data.spawn_location:to_position()
      end)
    end)

  end)
end

add(picotest.test_suite, test_stage)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('stage', test_stage)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
