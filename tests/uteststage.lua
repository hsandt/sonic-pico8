require("bustedhelper")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")
local stage = require("game/ingame/stage")
local stage_data = require("game/data/stage_data")
local flow = require("engine/application/flow")
local titlemenu = require("game/menu/titlemenu")
local audio = require("game/resources/audio")
local gamestate = require("game/application/gamestate")
-- only to stub class method in setup without needing instance (created in before_each)
local player_character = require("game/ingame/playercharacter")

describe('stage', function ()

  describe('state.type', function ()
    it('should be gamestate.types.stage', function ()
      assert.are_equal(gamestate.types.stage, stage.state.type)
    end)
  end)

  describe('coroutine', function ()

    describe('working coroutine function', function ()

      local test_var = 0

      local function set_var_after_delay_async(delay, value)
        yield_delay(delay)
        test_var = value
      end

      describe('start_coroutine', function ()

        setup(function ()
          stage.state:start_coroutine(set_var_after_delay_async)
        end)

        teardown(function ()
          clear_table(stage.state.coroutine_curries)
        end)

        it('should start a coroutine, stopping at the first yield', function ()
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(0, test_var)
        end)

      end)

      describe('(2 coroutines started with yield_delays of 1.0 and 2.0 resp.)', function ()

        before_each(function ()
          test_var = 0
          stage.state:start_coroutine(set_var_after_delay_async, 1.0, 1)
          stage.state:start_coroutine(set_var_after_delay_async, 2.0, 2)
        end)

        after_each(function ()
          clear_table(stage.state.coroutine_curries)
        end)

        describe('update_coroutines', function ()

          it('should update all the coroutines (not enough time to finish any coroutine)', function ()
            for t = 1, 1.0 * fps - 1 do
              stage.state:update_coroutines()
            end
            assert.are_equal(2, #stage.state.coroutine_curries)
            assert.are_same({"suspended", "suspended"}, {costatus(stage.state.coroutine_curries[1].coroutine), costatus(stage.state.coroutine_curries[2].coroutine)})
            assert.are_equal(0, test_var)
          end)

          it('should update all the coroutines (just enough time to finish the first one but not the second one)', function ()
            for t = 1, 1.0 * fps do
              stage.state:update_coroutines()
            end
            assert.are_equal(2, #stage.state.coroutine_curries)
            assert.are_same({"dead", "suspended"}, {costatus(stage.state.coroutine_curries[1].coroutine), costatus(stage.state.coroutine_curries[2].coroutine)})
            assert.are_equal(1, test_var)
          end)

          it('should remove dead coroutines on the next call after finish (remove first one when dead)', function ()
            for t = 1, 1.0 * fps + 1 do
              stage.state:update_coroutines()
            end
            -- 1st coroutine has been removed, so the only coroutine left at index 1 is now the 2nd coroutine
            assert.are_equal(1, #stage.state.coroutine_curries)
            assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
            assert.are_equal(1, test_var)
          end)

          it('should update all the coroutines (just enough time to finish the second one)', function ()
            for t = 1, 2.0 * fps do
              stage.state:update_coroutines()
            end
            assert.are_equal(1, #stage.state.coroutine_curries)
            assert.are_equal("dead", costatus(stage.state.coroutine_curries[1].coroutine))
            assert.are_equal(2, test_var)
          end)

          it('should remove dead coroutines on the next call after finish (remove second one when dead)', function ()
            for t = 1, 2.0 * fps + 1 do
              stage.state:update_coroutines()
            end
            assert.are_equal(0, #stage.state.coroutine_curries)
            assert.are_equal(2, test_var)
          end)

        end)  -- update_coroutines

      end)  -- (2 coroutines started with yield_delays of 1.0 and 2.0 resp.)

    end)  -- working coroutine function

    describe('coroutine updating coroutines', function ()

      local test_var = 0
      local warn_stub

      local function update_coroutine_recursively_async()
        test_var = test_var + 1
        stage.state:update_coroutines()
      end

      setup(function ()
        stage.state:start_coroutine(update_coroutine_recursively_async)
        warn_stub = stub(_G, "warn")
      end)

      teardown(function ()
        clear_table(stage.state.coroutine_curries)
        warn_stub:revert()
      end)

      after_each(function ()
        warn_stub:clear()
      end)

      it('should resume the coroutine on 1 level only and warn that you shouldn\'t update resume already running coroutines', function ()
        stage.state:update_coroutines()
        assert.are_equal(1, test_var)  -- proves we entered the coroutine function only once
        assert.spy(warn_stub).was_called(1)
        assert.spy(warn_stub).was_called_with(match.matches("stage.state:update_coroutines: coroutine should not be running outside its body: "), "flow")
      end)

    end)

    describe('(failing coroutine started)', function ()

      local function fail_async(delay)
        yield_delay(delay)
        error("fail_async finished")
      end

      before_each(function ()
        stage.state:start_coroutine(fail_async, 1.0)
      end)

      after_each(function ()
        clear_table(stage.state.coroutine_curries)
      end)

      describe('update_coroutines', function ()

        it('should not assert when an error doesn\'t occurs inside the coroutine resume yet', function ()
          assert.has_no_errors(function () stage.state:update_coroutines() end)
        end)

        it('should assert when an error occurs inside the coroutine resume', function ()
          assert.has_errors(function ()
              for t = 1, 1.0 * fps do
                stage.state:update_coroutines()
              end
            end,
            "Assertion failed in coroutine update for: [coroutine_curry] (dead) (1.0)")
        end)

      end)

    end)  -- (failing coroutine started)

    describe('(coroutine method for custom class started with yield_delay of 1.0)', function ()

      local test_class = new_class()
      local test_instance

      function test_class:_init(value)
        self.value = value
      end

      function test_class:set_value_after_delay(new_value)
        yield_delay(1.0)
        self.value = new_value
      end

      before_each(function ()
        -- create an instance and pass it to start_coroutine as the future self arg
        -- (start_coroutine_method only works for the instance of stage.state itself)
        test_instance = test_class(-10)
        stage.state:start_coroutine(test_class.set_value_after_delay, test_instance, 99)
      end)

      after_each(function ()
        clear_table(stage.state.coroutine_curries)
      end)

      describe('update_coroutines', function ()

        it('should update all the coroutines (not enough time to finish any coroutine)', function ()
          for t = 1, 1.0 * fps - 1 do
            stage.state:update_coroutines()
          end
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(-10, test_instance.value)
        end)

        it('should update all the coroutines (just enough time to finish)', function ()
          for t = 1, 1.0 * fps do
            stage.state:update_coroutines()
          end
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("dead", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(99, test_instance.value)
        end)

        it('should remove dead coroutines on the next call after finish after finish', function ()
          for t = 1, 1.0 * fps + 1 do
            stage.state:update_coroutines()
          end
          assert.are_equal(0, #stage.state.coroutine_curries)
          assert.are_equal(99, test_instance.value)
        end)

      end)

    end)

    describe('stage coroutine method', function ()

      -- create a dummy method and add it to stage.state
      function stage.state:set_extra_value_after_delay(new_value)
        yield_delay(1.0)
        self.extra_value = new_value
      end

      describe('start_coroutine_method', function ()

        setup(function ()
          stage.state.extra_value = -10
          stage.state:start_coroutine_method(stage.state.set_extra_value_after_delay, 99)
        end)

        teardown(function ()
          clear_table(stage.state.coroutine_curries)
        end)

        it('should start a coroutine method, stopping at the first yield', function ()
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(-10, stage.state.extra_value)
        end)

      end)

      describe('(stage coroutine method started)', function ()

        before_each(function ()
          stage.state.extra_value = -10
          stage.state:start_coroutine_method(stage.state.set_extra_value_after_delay, 99)
        end)

        after_each(function ()
          clear_table(stage.state.coroutine_curries)
        end)

        it('should start a coroutine method', function ()
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(-10, stage.state.extra_value)
        end)

        it('should not set self.extra_value to 99 only after 59 frames', function ()
          for t = 1, 1.0 * fps - 1 do
            stage.state:update_coroutines()
          end
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(-10, stage.state.extra_value)
        end)

        it('should set stage.state.extra_value to 99 after 1s (60 frames) with coroutine dead not removed', function ()
          for t = 1, 1.0 * fps  do
            stage.state:update_coroutines()
          end
          assert.are_equal(1, #stage.state.coroutine_curries)
          assert.are_equal("dead", costatus(stage.state.coroutine_curries[1].coroutine))
          assert.are_equal(99, stage.state.extra_value)
        end)

        it('should remove the now dead coroutine', function ()
          for t = 1, 1.0 * fps + 1 do
            stage.state:update_coroutines()
          end
          assert.are_equal(0, #stage.state.coroutine_curries)
          assert.are_equal(99, stage.state.extra_value)
        end)

      end)  -- (stage coroutine method started)

    end)  -- 'stage coroutine method'

  end)  -- coroutine

  describe('state', function ()

    after_each(function ()
      stage.state:init()
    end)

    it('. init', function ()
      assert.are_same({
          gamestate.types.stage,
          {},
          1,
          stage.substates.play,
          nil,
          false,
          vector.zero(),
          ui.overlay(0)
        },
        {
          stage.state.type,
          stage.state.coroutine_curries,
          stage.state.current_stage_id,
          stage.state.current_substate,
          stage.state.player_character,
          stage.state.has_reached_goal,
          stage.state.camera_position,
          stage.state.title_overlay
        })
    end)

    describe('on_enter', function ()

      local spawn_player_character_stub
      local handle_input_stub
      local play_bgm_stub

      setup(function ()
        spawn_player_character_stub = stub(stage.state, "spawn_player_character")
        start_coroutine_method_stub = stub(stage.state, "start_coroutine_method")
        play_bgm_stub = stub(stage.state, "play_bgm")
      end)

      teardown(function ()
        spawn_player_character_stub:revert()
        start_coroutine_method_stub:revert()
        play_bgm_stub:revert()
      end)

      after_each(function ()
        spawn_player_character_stub:clear()
        start_coroutine_method_stub:clear()
        play_bgm_stub:clear()
      end)

      before_each(function ()
        stage.state:on_enter()
      end)

      it('should enter the play substates', function ()
        assert.are_equal(stage.substates.play, stage.state.current_substate)
      end)

      it('should call spawn_player_character', function ()
        assert.spy(spawn_player_character_stub).was_called(1)
        assert.spy(spawn_player_character_stub).was_called_with(match.ref(stage.state))
      end)

      it('should set has_reached_goal to false', function ()
        assert.is_false(stage.state.has_reached_goal)
      end)

      it('should initialize camera at origin', function ()
        assert.are_equal(vector:zero(), stage.state.camera_position)
      end)

      it('should call start_coroutine_method on show_stage_title_async', function ()
        assert.spy(start_coroutine_method_stub).was_called(1)
        assert.spy(start_coroutine_method_stub).was_called_with(match.ref(stage.state), stage.state.show_stage_title_async)
      end)

      it('should call start_coroutine_method on show_stage_title_async', function ()
        assert.spy(play_bgm_stub).was_called(1)
        assert.spy(play_bgm_stub).was_called_with(match.ref(stage.state))
      end)

    end)

    describe('on_exit', function ()

      local title_overlay_clear_labels_stub
      local handle_input_stub
      local stop_bgm_stub

      setup(function ()
        title_overlay_clear_labels_stub = stub(stage.state, "spawn_player_character")
        start_coroutine_method_stub = stub(stage.state, "start_coroutine_method")
        stop_bgm_stub = stub(stage.state, "stop_bgm")
      end)

      teardown(function ()
        title_overlay_clear_labels_stub:revert()
        start_coroutine_method_stub:revert()
        stop_bgm_stub:revert()
      end)

      after_each(function ()
        title_overlay_clear_labels_stub:clear()
        start_coroutine_method_stub:clear()
        stop_bgm_stub:clear()
      end)

      before_each(function ()
        -- enter first, so we can check if on_exit cleans state correctly
        stage.state:on_enter()
        stage.state:on_exit()
      end)

      it('should clear all the coroutines', function ()
        assert.are_same({}, stage.state.coroutine_curries)
      end)

      it('should clear the player character', function ()
        assert.is_nil(stage.state.player_character)
      end)

      it('should call title_overlay:clear_labels', function ()
        assert.spy(title_overlay_clear_labels_stub).was_called(1)
        assert.spy(title_overlay_clear_labels_stub).was_called_with(match.ref(stage.state))
      end)

      it('should reset pico8 camera', function ()
        assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
      end)

      it('should call stop_bgm', function ()
        assert.spy(stop_bgm_stub).was_called(1)
        assert.spy(stop_bgm_stub).was_called_with(match.ref(stage.state))
      end)

    end)

    describe('spawn_player_character', function ()

      setup(function ()
        spy.on(player_character, "spawn_at")
      end)

      teardown(function ()
        player_character.spawn_at:revert()
      end)

      it('should spawn the player character at the stage spawn location', function ()
        stage.state:spawn_player_character()
        local player_char = stage.state.player_character
        assert.is_not_nil(player_char)
        local spawn_position = stage.state.current_stage_data.spawn_location:to_center_position()

        -- interface
        assert.are_equal(spawn_position, player_char.position)
        -- we haven't initialized any map in busted, so the character is in the air and spawn_at detected this
        assert.are_equal(motion_states.airborne, player_char.motion_state)

        -- implementation
        assert.spy(player_char.spawn_at).was_called(1)
        assert.spy(player_char.spawn_at).was_called_with(match.ref(stage.state.player_character), spawn_position)
      end)

    end)

    describe('(stage states added)', function ()

      setup(function ()
        flow:add_gamestate(stage.state)
        flow:add_gamestate(titlemenu.state)  -- for transition on reached goal
      end)

      teardown(function ()
        clear_table(flow.gamestates)
      end)

      describe('(stage state entered)', function ()

        before_each(function ()
          flow:_change_gamestate(stage.state)
        end)

        after_each(function ()
          flow.current_gamestate:on_exit()
          flow.current_gamestate = nil
        end)

        describe('player_character', function ()

          describe('handle_input', function ()

            after_each(function ()
              input.players_button_states[0][button_ids.left] = button_states.released
              input.players_button_states[0][button_ids.right] = button_states.released
              input.players_button_states[0][button_ids.up] = button_states.released
              input.players_button_states[0][button_ids.down] = button_states.released
              input.players_button_states[0][button_ids.o] = button_states.released

              stage.state.player_character.move_intention = vector.zero()
              stage.state.player_character.jump_intention = false
              stage.state.player_character.hold_jump_intention = false
            end)

            describe('(when player character control mode is not human)', function ()

              before_each(function ()
                stage.state.player_character.control_mode = control_modes.ai
              end)

              it('should do nothing', function ()
                input.players_button_states[0][button_ids.left] = button_states.pressed
                stage.state:handle_input()
                assert.are_equal(vector:zero(), stage.state.player_character.move_intention)
                input.players_button_states[0][button_ids.up] = button_states.pressed
                stage.state:handle_input()
                assert.are_equal(vector:zero(), stage.state.player_character.move_intention)
              end)

            end)

            -- control mode is human by default

            it('(when input left in down) it should update the player character\'s move intention by (-1, 0)', function ()
              input.players_button_states[0][button_ids.left] = button_states.pressed
              stage.state:handle_input()
              assert.are_equal(vector(-1, 0), stage.state.player_character.move_intention)
            end)

            it('(when input right in down) it should update the player character\'s move intention by (1, 0)', function ()
              input.players_button_states[0][button_ids.right] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_equal(vector(1, 0), stage.state.player_character.move_intention)
            end)

            it('(when input left and right are down) it should update the player character\'s move intention by (-1, 0)', function ()
              input.players_button_states[0][button_ids.left] = button_states.pressed
              input.players_button_states[0][button_ids.right] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_equal(vector(-1, 0), stage.state.player_character.move_intention)
            end)

             it('(when input up in down) it should update the player character\'s move intention by (-1, 0)', function ()
              input.players_button_states[0][button_ids.up] = button_states.pressed
              stage.state:handle_input()
              assert.are_equal(vector(0, -1), stage.state.player_character.move_intention)
            end)

            it('(when input down in down) it should update the player character\'s move intention by (0, 1)', function ()
              input.players_button_states[0][button_ids.down] = button_states.pressed
              stage.state:handle_input()
              assert.are_equal(vector(0, 1), stage.state.player_character.move_intention)
            end)

            it('(when input up and down are down) it should update the player character\'s move intention by (0, -1)', function ()
              input.players_button_states[0][button_ids.up] = button_states.just_pressed
              input.players_button_states[0][button_ids.down] = button_states.pressed
              stage.state:handle_input()
              assert.are_equal(vector(0, -1), stage.state.player_character.move_intention)
            end)

            it('(when input left and up are down) it should update the player character\'s move intention by (-1, -1)', function ()
              input.players_button_states[0][button_ids.left] = button_states.just_pressed
              input.players_button_states[0][button_ids.up] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_equal(vector(-1, -1), stage.state.player_character.move_intention)
            end)

            it('(when input left and down are down) it should update the player character\'s move intention by (-1, 1)', function ()
              input.players_button_states[0][button_ids.left] = button_states.just_pressed
              input.players_button_states[0][button_ids.down] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_equal(vector(-1, 1), stage.state.player_character.move_intention)
            end)

            it('(when input right and up are down) it should update the player character\'s move intention by (1, -1)', function ()
              input.players_button_states[0][button_ids.right] = button_states.just_pressed
              input.players_button_states[0][button_ids.up] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_equal(vector(1, -1), stage.state.player_character.move_intention)
            end)

            it('(when input right and down are down) it should update the player character\'s move intention by (1, 1)', function ()
              input.players_button_states[0][button_ids.right] = button_states.just_pressed
              input.players_button_states[0][button_ids.down] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_equal(vector(1, 1), stage.state.player_character.move_intention)
            end)

            it('(when input o is released) it should update the player character\'s jump intention to false, hold jump intention to false', function ()
              stage.state:handle_input()
              assert.are_same({false, false}, {stage.state.player_character.jump_intention, stage.state.player_character.hold_jump_intention})
            end)

            it('(when input o is just pressed) it should update the player character\'s jump intention to true, hold jump intention to true', function ()
              input.players_button_states[0][button_ids.o] = button_states.just_pressed
              stage.state:handle_input()
              assert.are_same({true, true}, {stage.state.player_character.jump_intention, stage.state.player_character.hold_jump_intention})
            end)

            it('(when input o is pressed) it should update the player character\'s jump intention to false, hold jump intention to true', function ()
              input.players_button_states[0][button_ids.o] = button_states.pressed
              stage.state:handle_input()
              assert.are_same({false, true}, {stage.state.player_character.jump_intention, stage.state.player_character.hold_jump_intention})
            end)

          end)

        end)

        describe('update_camera', function ()

          before_each(function ()
            stage.state.player_character.position = vector(12, 24)
          end)

          it('should move the camera to player position', function ()
            stage.state:update_camera()
            assert.are_equal(vector(12, 24), stage.state.camera_position)
          end)

        end)

        describe('update', function ()

          local update_coroutines_stub
          local handle_input_stub
          local player_character_update_stub
          local check_reached_goal_stub
          local update_camera_stub

          setup(function ()
            update_coroutines_stub = stub(stage.state, "update_coroutines")
            handle_input_stub = stub(stage.state, "handle_input")
            player_character_update_stub = stub(player_character, "update")
            check_reached_goal_stub = stub(stage.state, "check_reached_goal")
            update_camera_stub = stub(stage.state, "update_camera")
          end)

          teardown(function ()
            update_coroutines_stub:revert()
            handle_input_stub:revert()
            player_character_update_stub:revert()
            check_reached_goal_stub:revert()
            update_camera_stub:revert()
          end)

          after_each(function ()
            update_coroutines_stub:clear()
            handle_input_stub:clear()
            player_character_update_stub:clear()
            check_reached_goal_stub:clear()
            update_camera_stub:clear()
          end)

          describe('(current substate is play)', function ()

            it('should call handle_input, player_character:update, check_reached_goal and update_camera', function ()
              stage.state.current_substate = stage.substates.play
              stage.state:update()
              assert.spy(update_coroutines_stub).was_called(1)
              assert.spy(update_coroutines_stub).was_called_with(match.ref(stage.state))
              assert.spy(handle_input_stub).was_called(1)
              assert.spy(handle_input_stub).was_called_with(match.ref(stage.state))
              assert.spy(player_character_update_stub).was_called(1)
              assert.spy(player_character_update_stub).was_called_with(match.ref(stage.state.player_character))
              assert.spy(check_reached_goal_stub).was_called(1)
              assert.spy(check_reached_goal_stub).was_called_with(match.ref(stage.state))
              assert.spy(update_camera_stub).was_called(1)
              assert.spy(update_camera_stub).was_called_with(match.ref(stage.state))      end)
          end)

          describe('(current substate is result)', function ()

            it('should call handle_input, player_character:update, check_reached_goal and update_camera', function ()
              stage.state.current_substate = stage.substates.result
              stage.state:update()
              assert.spy(update_coroutines_stub).was_called(1)
              assert.spy(update_coroutines_stub).was_called_with(match.ref(stage.state))
              assert.spy(handle_input_stub).was_not_called()
              assert.spy(player_character_update_stub).was_not_called()
              assert.spy(check_reached_goal_stub).was_not_called()
              assert.spy(update_camera_stub).was_not_called()
            end)

          end)

        end)  -- update

        describe('render', function ()

          local render_background_stub
          local render_stage_elements_stub
          local render_title_overlay_stub

          setup(function ()
            render_background_stub = stub(stage.state, "render_background")
            render_stage_elements_stub = stub(stage.state, "render_stage_elements")
            render_title_overlay_stub = stub(stage.state, "render_title_overlay")
          end)

          teardown(function ()
            render_background_stub:revert()
            render_stage_elements_stub:revert()
            render_title_overlay_stub:revert()
          end)

          after_each(function ()
            render_background_stub:clear()
            render_stage_elements_stub:clear()
            render_title_overlay_stub:clear()
          end)

          it('should reset camera, call render_background, render_stage_elements, render_title_overlay', function ()
            stage.state:render()
            assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
            assert.spy(render_background_stub).was_called(1)
            assert.spy(render_background_stub).was_called_with(match.ref(stage.state))
            assert.spy(render_stage_elements_stub).was_called(1)
            assert.spy(render_stage_elements_stub).was_called_with(match.ref(stage.state))
            assert.spy(render_title_overlay_stub).was_called(1)
            assert.spy(render_title_overlay_stub).was_called_with(match.ref(stage.state))
          end)

        end)  -- state.render

      end)  -- (enter stage state)

      describe('(enter stage state each time)', function ()

        before_each(function ()
          flow:_change_gamestate(stage.state)

          -- clear any intro or back to title menu coroutines so the tests on coroutine curries are not messed up
          clear_table(stage.state.coroutine_curries)
        end)

        after_each(function ()
          stage.state.has_reached_goal = false
          flow.current_gamestate:on_exit()  -- whatever the current gamestate is
          flow.current_gamestate = nil
        end)

        describe('check_reached_goal', function ()

          describe('(before the goal)', function ()

            -- should be each
            before_each(function ()
              stage.state.player_character.position = vector(stage.state.current_stage_data.goal_x - 1, 0)
              stage.state:check_reached_goal()
            end)

            it('should not set has_reached_goal to true', function ()
              assert.is_false(stage.state.has_reached_goal)
            end)

            it('should not start on_reached_goal_async', function ()
              assert.are_equal(0, #stage.state.coroutine_curries)
            end)

          end)

          describe('(just on the goal)', function ()

            before_each(function ()
              stage.state.player_character.position = vector(stage.state.current_stage_data.goal_x, 0)
              stage.state:check_reached_goal()
            end)

            it('should set has_reached_goal to true', function ()
              assert.is_true(stage.state.has_reached_goal)
            end)

            it('should start on_reached_goal_async', function ()
              assert.are_equal(1, #stage.state.coroutine_curries)
              assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
            end)

          end)

          describe('(after the goal)', function ()

            before_each(function ()
              stage.state.player_character.position = vector(stage.state.current_stage_data.goal_x + 1, 0)
              stage.state:check_reached_goal()
            end)

            it('should set has_reached_goal to true', function ()
              assert.is_true(stage.state.has_reached_goal)
            end)

            it('should start on_reached_goal_async', function ()
              assert.are_equal(1, #stage.state.coroutine_curries)
              assert.are_equal("suspended", costatus(stage.state.coroutine_curries[1].coroutine))
            end)

          end)

        end)

        describe('state.on_reached_goal_async', function ()

          before_each(function ()
            stage.state:start_coroutine_method(stage.state.on_reached_goal_async)
          end)

          it('should set substate to result after 1 update', function ()
            flow:update()

            assert.are_equal(stage.substates.result, stage.state.current_substate)
          end)

          it('should change gamestate to titlemenu after 1.0s + 1 update to apply the query next state', function ()
            for i = 1, stage_data.back_to_titlemenu_delay * fps + 1 do
              flow:update()
            end
            assert.are_equal(gamestate.types.titlemenu, flow.current_gamestate.type)
          end)

        end)

        describe('state.feedback_reached_goal', function ()
          local sfx_stub

          setup(function ()
            sfx_stub = stub(_G, "sfx")
          end)

          teardown(function ()
            sfx_stub:revert()
          end)

          after_each(function ()
            sfx_stub:clear()
          end)

          it('should play goal_reached sfx', function ()
            stage.state:feedback_reached_goal()
            assert.spy(sfx_stub).was_called(1)
            assert.spy(sfx_stub).was_called_with(audio.sfx_ids.goal_reached)
          end)

        end)

        describe('back_to_titlemenu', function ()

          it('should change gamestate to titlemenu on next update', function ()
            stage.state:back_to_titlemenu()
            flow:update()
            assert.are_equal(gamestate.types.titlemenu, flow.current_gamestate.type)
          end)

        end)

        describe('(no overlay labels)', function ()

          before_each(function ()
            clear_table(stage.state.title_overlay.labels)
          end)

          it('show_stage_title_async should add a title label and remove it after global.show_stage_title_delay', function ()
            stage.state:start_coroutine_method(stage.state.show_stage_title_async)
            stage.state:update_coroutines()
            assert.are_equal(ui.label(stage.state.current_stage_data.title, vector(50, 30), colors.white), stage.state.title_overlay.labels["title"])
            for i = 2, stage_data.show_stage_title_delay*fps do
              stage.state:update_coroutines()
            end
            assert.is_nil(stage.state.title_overlay.labels["title"])
          end)

        end)

        describe('state render methods', function ()

          local map_stub
          local player_character_render_stub

          setup(function ()
            rectfill_stub = stub(_G, "rectfill")
            map_stub = stub(_G, "map")
            spy.on(stage.state, "render_environment")
            player_character_render_stub = stub(player_character, "render")
            title_overlay_draw_labels_stub = stub(stage.state.title_overlay, "draw_labels")
          end)

          teardown(function ()
            rectfill_stub:clear()
            map_stub:clear()
            stage.state.render_environment:clear()
            player_character_render_stub:clear()
            title_overlay_draw_labels_stub:clear()
          end)

          before_each(function ()
            spy.on(stage.state, "render_environment")
            stage.state:set_camera_offset_stage()
          end)

          after_each(function ()
            rectfill_stub:revert()
            map_stub:revert()
            stage.state.render_environment:revert()
            player_character_render_stub:revert()
            title_overlay_draw_labels_stub:revert()
          end)

          it('set_camera_offset_stage should set the pico8 camera so that it is centered on the camera position', function ()
            stage.state.camera_position = vector(24, 13)
            stage.state:set_camera_offset_stage()
            assert.are_equal(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
          end)

          it('render_background should reset camera position, call rectfill on the whole screen with stage background color', function ()
            stage.state.camera_position = vector(24, 13)
            stage.state:render_background()
            assert.are_equal(vector(0, 0), vector(pico8.camera_x, pico8.camera_y))
            assert.spy(rectfill_stub).was_called(1)
            assert.spy(rectfill_stub).was_called_with(0, 0, 127, 127, stage.state.current_stage_data.background_color)
          end)

          it('render_stage_elements should set camera position, call map for environment and player_character:render', function ()
            stage.state.camera_position = vector(24, 13)
            stage.state:render_stage_elements()
            assert.are_equal(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
            assert.spy(stage.state.render_environment).was_called(1)
            assert.spy(stage.state.render_environment).was_called_with(match.ref(stage.state))
            assert.spy(player_character_render_stub).was_called(1)
            assert.spy(player_character_render_stub).was_called_with(match.ref(stage.state.player_character))
          end)

          it('render_environment should call map', function ()
            stage.state:render_environment()
            assert.spy(map_stub).was_called(1)
            assert.spy(map_stub).was_called_with(0, 0, 0, 0, stage.state.current_stage_data.width, stage.state.current_stage_data.height)
          end)

          it('render_player_character should call player_character:render', function ()
            stage.state:render_player_character()
            assert.spy(player_character_render_stub).was_called(1)
            assert.spy(player_character_render_stub).was_called_with(match.ref(stage.state.player_character))
          end)

          it('render_title_overlay should call title_overlay:draw_labels', function ()
            stage.state:render_title_overlay()
            assert.are_equal(vector.zero(), vector(pico8.camera_x, pico8.camera_y))
            assert.spy(title_overlay_draw_labels_stub).was_called(1)
            assert.spy(title_overlay_draw_labels_stub).was_called_with(stage.state.title_overlay)
          end)

        end)  -- state render methods

        describe('state audio methods', function ()

          after_each(function ()
            pico8.current_music = nil
          end)

          it('play_bgm should start level bgm', function ()
            stage.state:play_bgm()
            assert.are_same({music=audio.music_pattern_ids.green_hill, fadems=0, channel_mask=0}, pico8.current_music)
          end)

          it('stop_bgm should stop level bgm if started, else do nothing', function ()
            stage.state:stop_bgm()
            assert.is_nil(pico8.current_music)
            stage.state:play_bgm()
            stage.state:stop_bgm()
            assert.is_nil(pico8.current_music)
            stage.state:play_bgm()
            stage.state:stop_bgm(2.0)
            assert.is_nil(pico8.current_music)
          end)

        end)  -- state audio methods

        describe('on exit stage state to enter titlemenu state', function ()

          before_each(function ()
            flow:_change_gamestate(titlemenu.state)
          end)

          it('player character should be nil', function ()
            assert.is_nil(stage.state.player_character)
          end)

          it('title overlay should be empty', function ()
            assert.is_not_nil(stage.state.title_overlay)
            assert.is_not_nil(stage.state.title_overlay.labels)
            assert.is_true(is_empty(stage.state.title_overlay.labels))
          end)

          describe('reenter stage state', function ()

            -- should be each
            before_each(function ()
              flow:_change_gamestate(stage.state)
            end)

            it('current substate should be play', function ()
              assert.are_equal(stage.substates.play, stage.state.current_substate)
            end)

            it('player character should not be nil and respawned at the spawn location', function ()
              assert.is_not_nil(stage.state.player_character)
              assert.are_equal(stage.state.current_stage_data.spawn_location:to_center_position(), stage.state.player_character.position)
            end)

            it('should not have reached goal', function ()
              assert.is_false(stage.state.has_reached_goal)
            end)

          end)

        end)  -- on exit stage state to enter titlemenu state

      end)  -- (enter stage state each time)

    end)  -- (stage states added)

  end)  -- (stage state)

end)
