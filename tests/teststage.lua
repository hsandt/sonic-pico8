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

  desc('start_coroutine(set_var_after_delay_d) and update_coroutines', function ()

    local test_var = 0

    local function set_var_after_delay_d()
      yield_delay(1.0)
      test_var = 1
    end

    stage_state:start_coroutine(set_var_after_delay_d)

    it('should start a coroutine', function ()
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        test_var == 0
    end)

    it('should not set test_var to 1 only after 59 frames', function ()
      for t = 1, 1.0*fps-1 do
        stage_state:update_coroutines()
      end
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        test_var == 0
    end)

    it('should set test_var to 1 after 1s (60 frames) with coroutine dead', function ()
      stage_state:update_coroutines()  -- one more to reach 60
      return #stage.state.coroutine_curries == 1 and
        costatus(stage_state.coroutine_curries[1].coroutine) == "dead",
        test_var == 1
    end)

    it('should remove the now dead coroutine', function ()
      stage_state:update_coroutines()  -- just to remove dead coroutine
      return #stage.state.coroutine_curries == 0
    end)

    clear_table(stage_state.coroutine_curries)

  end)

  desc('start_coroutine(set_value_after_delay instance) and update_coroutines', function ()

    local test_class = new_class()

    function test_class:_init(value)
      self.value = value
    end

    function test_class:set_value_after_delay(new_value)
      yield_delay(1.0)
      self.value = new_value
    end

    -- create an instance and pass it to start_coroutine as the future self arg
    -- (start_coroutine_method only works for the instance of stage_state itself)
    test_instance = test_class(-10)
    stage_state:start_coroutine(test_class.set_value_after_delay, test_instance, 99)

    it('should start a coroutine with passed instance', function ()
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        test_instance.value == -10
    end)

    it('should not set test_instance.value to 99 only after 59 frames', function ()
      for t = 1, 1.0*fps-1 do
        stage_state:update_coroutines()
      end
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        test_instance.value == -10
    end)

    it('should set test_instance.value to 99 after 1s with coroutine dead', function ()
      stage_state:update_coroutines()  -- one more to reach 60
      return #stage.state.coroutine_curries == 1 and
        costatus(stage_state.coroutine_curries[1].coroutine) == "dead",
        test_instance.value == 99
    end)

    it('should remove the now dead coroutine', function ()
      stage_state:update_coroutines()  -- just to remove dead coroutine
      return #stage.state.coroutine_curries == 0
    end)

    clear_table(stage_state.coroutine_curries)

  end)

  desc('start_coroutine_method(set_value_after_delay) and update_coroutines', function ()

    -- create a dummy method and add it to stage.state
    function stage_state:set_extra_value_after_delay(new_value)
      yield_delay(1.0)
      self.extra_value = new_value
    end

    stage_state.extra_value = -10
    stage_state:start_coroutine_method(stage_state.set_extra_value_after_delay, 99)

    it('should start a coroutine method', function ()
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        stage_state.extra_value == -10
    end)

    it('should not set self.extra_value to 99 only after 59 frames', function ()
      for t = 1, 1.0*fps-1 do
        stage_state:update_coroutines()
      end
      return #stage_state.coroutine_curries == 1,
        #stage_state.coroutine_curries == 1 and
          costatus(stage_state.coroutine_curries[1].coroutine) == "suspended",
        stage_state.extra_value == -10
    end)

    it('should set stage_state.extra_value to 99 after 1s (60 frames) with coroutine dead not removed', function ()
      stage_state:update_coroutines()  -- one more to reach 60
      return #stage.state.coroutine_curries == 1 and
        costatus(stage_state.coroutine_curries[1].coroutine) == "dead",
        stage_state.extra_value == 99
    end)

    it('should remove the now dead coroutine', function ()
      stage_state:update_coroutines()  -- just to remove dead coroutine
      return #stage_state.coroutine_curries == 0
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

    it('current substate should be play', function ()
      return stage_state.current_substate == stage.substates.play
    end)

    it('should not have reached goal', function ()
      return not stage_state.has_reached_goal
    end)

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

        -- clear any intro coroutines so the tests on coroutine curries
        -- are not messed up
        clear_table(stage_state.coroutine_curries)

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

          clear_table(stage_state.coroutine_curries)  -- important to prevent changing state and mess up further tests
          stage_state.has_reached_goal = false
          stage_state.player_character.position = stage.data.spawn_location:to_center_position()

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

          clear_table(stage_state.coroutine_curries)  -- important to prevent changing state and mess up further tests
          stage_state.has_reached_goal = false
          stage_state.player_character.position = stage.data.spawn_location:to_center_position()

        end)

      end)

      desc('stage_state.on_reached_goal_async', function ()

        stage_state:on_reached_goal_async()

        it('should set substate to result', function ()
          return stage_state.current_substate == stage.substates.result
        end)

        it('should change gamestate to titlemenu after 1.0s', function ()
          for i = 1, stage.global_params.back_to_titlemenu_delay * fps do
            flow:update()
          end
          return flow.current_gamestate.type == gamestate_type.titlemenu
        end)

        flow:_change_gamestate(stage_state)  -- will also reset current_substate

      end)

      desc('stage_state.feedback_reached_goal', function ()
        stage_state:feedback_reached_goal()
        return true  -- hard to test sfx, but at least it didn't crash
      end)

      desc('stage_state.back_to_titlemenu', function ()

        stage_state:back_to_titlemenu()
        flow:update()

        it('should change gamestate to titlemenu on next update', function ()
          return flow.current_gamestate.type == gamestate_type.titlemenu
        end)

        flow:_change_gamestate(stage_state)

      end)

      desc('stage_state render methods', function ()

        it('set_camera_offset_stage should not crash', function ()
          stage_state:set_camera_offset_stage()
          return true
        end)

        it('render_environment should not crash', function ()
          stage_state:render_environment()
          return true
        end)

        it('render_player_character should not crash', function ()
          stage_state:render_player_character()
          return true
        end)

        it('render_title_overlay should not crash', function ()
          stage_state:render_title_overlay()
          return true
        end)

      end)

    end)

    desc('on exit stage state', function ()

      flow:_change_gamestate(titlemenu.state)

      it('player character should be nil', function ()
        return stage_state.player_character == nil
      end)

      it('title overlay should be empty', function ()
        return not stage_state.title_overlay ~= nil,
          stage_state.title_overlay ~= nil and
            stage_state.title_overlay.labels ~= nil,
          stage_state.title_overlay ~= nil and
            stage_state.title_overlay.labels ~= nil and
            is_empty(stage_state.title_overlay.labels)
      end)

    end)

    desc('reenter stage state', function ()

      flow:_change_gamestate(stage_state)

      it('current substate should be play', function ()
        return stage_state.current_substate == stage.substates.play
      end)

      it('player character should not be nil and respawned at the spawn location', function ()
        return stage_state.player_character ~= nil,
          stage_state.player_character ~= nil and
            stage_state.player_character.position == stage.data.spawn_location:to_center_position()
      end)

      it('should not have reached goal', function ()
        return not stage_state.has_reached_goal
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
