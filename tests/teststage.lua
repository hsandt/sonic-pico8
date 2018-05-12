local picotest = require("picotest")
local stage = require("stage")
local flow = require("flow")
local titlemenu = require("titlemenu")

function test_stage(desc,it)

  local stage_state = stage.state

  desc('stage.state.type', function ()
    it('should be gamestate_type.stage', function ()
      return stage_state.type == gamestate_type.stage
    end)
  end)

  desc('add_coroutine(set_var_after_delay_async) and update_coroutines', function ()

    local test_var = 0

    local function set_var_after_delay_async()
      yield_delay(1.0)
      test_var = 1
    end

    stage_state:add_coroutine(set_var_after_delay_async)

    it('should start a coroutine', function ()
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        test_var == 0
    end)

    it('should set test_var to 1 after 1s (60 frames) end and remove coroutine', function ()
      for t = 1, fps+20 do
        stage_state:update_coroutines()
      end
      return #stage_state.coroutine_curries == 0,
        test_var == 1
    end)

    clear_table(stage_state.coroutine_curries)

  end)

  desc('stage.state.spawn_player_character', function ()

    stage_state:spawn_player_character()

    it('should spawn the player character at the stage spawn location', function ()
      return stage_state.player_character ~= nil,
        stage_state.player_character ~= nil and
          stage_state.player_character.position == stage.data.spawn_location:to_center_position()

    end)

  end)

  desc('enter stage state', function ()

    flow:add_gamestate(stage_state)
    flow:add_gamestate(titlemenu.state)  -- for transition on reached goal
    flow:_change_gamestate(stage_state)

    desc('[after enter stage state] stage.stage.player_character', function ()

      it('should not be nil', function ()
        return stage_state.player_character ~= nil
      end)

      it('should be located at stage spawn location', function ()
        return stage_state.player_character ~= nil and
          stage_state.player_character.position == stage.data.spawn_location:to_center_position()
      end)

      desc('stage_state.update_camera', function ()

        stage_state.player_character.position = vector(12, 24)
        stage_state:update_camera()

        it('should move the camera to player position', function ()
          return stage_state.camera_position == vector(12, 24)
        end)

        stage_state.player_character.position = stage.data.spawn_location:to_center_position()
        stage_state.camera_position = vector.zero()

      end)

      desc('stage_state.check_reached_goal', function ()

        desc('(before the goal)', function ()

          stage_state.player_character.position = vector(stage.data.goal_x - 1, 0)
          stage_state:check_reached_goal()

          it('should not set has_reached_goal to true', function ()
            return not stage_state.has_reached_goal
          end)

          it('should not start on_reached_goal_async', function ()
            return #stage_state.coroutine_curries == 0
          end)

        end)

        desc('(just on the goal)', function ()

          stage_state.player_character.position = vector(stage.data.goal_x, 0)
          stage_state:check_reached_goal()

          it('should set has_reached_goal to true', function ()
            return stage_state.has_reached_goal
          end)

          it('should start on_reached_goal_async', function ()
            return #stage_state.coroutine_curries == 1,
              #stage_state.coroutine_curries == 1 and
                costatus(stage_state.coroutine_curries[1].coroutine) == "suspended"
          end)

          stage_state.player_character.position = stage.data.spawn_location:to_center_position()
          clear_table(stage_state.coroutine_curries)  -- important to prevent changing state and mess up further tests

        end)

        desc('(after the goal)', function ()

          stage_state.player_character.position = vector(stage.data.goal_x + 1, 0)
          stage_state:check_reached_goal()

          it('should set has_reached_goal to true', function ()
            return stage_state.has_reached_goal
          end)

          it('should start on_reached_goal_async', function ()
            return #stage_state.coroutine_curries == 1,
              #stage_state.coroutine_curries == 1 and
                costatus(stage_state.coroutine_curries[1].coroutine) == "suspended"
          end)

          stage_state.player_character.position = stage.data.spawn_location:to_center_position()
          clear_table(stage_state.coroutine_curries)  -- important to prevent changing state and mess up further tests

        end)

      end)

      desc('stage_state.on_reached_goal_async', function ()

        stage_state:on_reached_goal_async()
        for i = 1, stage.global_params.finish_stage_delay * fps do
          flow:update()
        end

        it('should change gamestate to titlemenu after 1.0s', function ()
          return flow.current_gamestate.type == gamestate_type.titlemenu
        end)

        flow:_change_gamestate(stage_state)

      end)

      desc('stage_state.finish_stage', function ()

        stage_state:finish_stage()
        flow:update()

        it('should change gamestate to titlemenu on next update', function ()
          return flow.current_gamestate.type == gamestate_type.titlemenu
        end)

        flow:_change_gamestate(stage_state)

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
