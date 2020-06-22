require("engine/test/bustedhelper")
local ui = require("engine/ui/ui")
local stage_state = require("ingame/stage_state")
local stage_data = require("data/stage_data")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local titlemenu = require("menu/titlemenu")
local audio = require("resources/audio")

local picosonic_app = require("application/picosonic_app")
-- only to stub class method in setup without needing instance (created in before_each)
local player_char = require("ingame/playercharacter")

describe('stage_state', function ()

  describe('static members', function ()

    it('type is ":stage"', function ()
      assert.are_equal(':stage', stage_state.type)
    end)

  end)

  describe('(with instance)', function ()

    local state

    before_each(function ()
      local app = picosonic_app()
      state = stage_state()
        -- no need to register gamestate properly, just add app member to pass tests
      state.app = app
    end)

    describe('state', function ()

      -- bugfix history: .
      it('init', function ()
        assert.are_same({
            ':stage',
            1,
            stage_state.substates.play,
            nil,
            false,
            vector.zero(),
            ui.overlay(0)
          },
          {
            state.type,
            state.curr_stage_id,
            state.current_substate,
            state.player_char,
            state.has_reached_goal,
            state.camera_pos,
            state.title_overlay
          })
      end)

      describe('on_enter', function ()

        setup(function ()
          stub(stage_state, "spawn_player_char")
          stub(picosonic_app, "start_coroutine")
          stub(stage_state, "play_bgm")
        end)

        teardown(function ()
          stage_state.spawn_player_char:revert()
          picosonic_app.start_coroutine:revert()
          stage_state.play_bgm:revert()
        end)

        after_each(function ()
          stage_state.spawn_player_char:clear()
          picosonic_app.start_coroutine:clear()
          stage_state.play_bgm:clear()
        end)

        before_each(function ()
          state:on_enter()
        end)

        it('should enter the play substates', function ()
          assert.are_equal(stage_state.substates.play, state.current_substate)
        end)

        it('should call spawn_player_char', function ()
          local s = assert.spy(stage_state.spawn_player_char)
          s.was_called(1)
          s.was_called_with(match.ref(state))
        end)

        it('should set has_reached_goal to false', function ()
          assert.is_false(state.has_reached_goal)
        end)

        it('should initialize camera at origin', function ()
          assert.are_equal(vector:zero(), state.camera_pos)
        end)

        it('should call start_coroutine_method on show_stage_title_async', function ()
          local s = assert.spy(picosonic_app.start_coroutine)
          s.was_called(1)
          s.was_called_with(match.ref(state.app), stage_state.show_stage_title_async, match.ref(state))
        end)

        it('should call start_coroutine_method on show_stage_title_async', function ()
          assert.spy(state.play_bgm).was_called(1)
          assert.spy(state.play_bgm).was_called_with(match.ref(state))
        end)

      end)

      describe('on_exit', function ()

        setup(function ()
          stub(ui.overlay, "clear_labels")
          stub(picosonic_app, "stop_all_coroutines")
          stub(stage_state, "stop_bgm")
        end)

        teardown(function ()
          ui.overlay.clear_labels:revert()
          picosonic_app.stop_all_coroutines:revert()
          stage_state.stop_bgm:revert()
        end)

        after_each(function ()
          ui.overlay.clear_labels:clear()
          picosonic_app.stop_all_coroutines:clear()
          stage_state.stop_bgm:clear()
        end)

        before_each(function ()
          -- enter first, so we can check if on_exit cleans state correctly
          state:on_enter()
          state:on_exit()
        end)

        it('should stop all the coroutines', function ()
          local s = assert.spy(picosonic_app.stop_all_coroutines)
          s.was_called(1)
          s.was_called_with(match.ref(state.app))
        end)

        it('should clear the player character', function ()
          assert.is_nil(state.player_char)
        end)

        it('should call title_overlay:clear_labels', function ()
          local s = assert.spy(ui.overlay.clear_labels)
          s.was_called(1)
          s.was_called_with(match.ref(state.title_overlay))
        end)

        it('should reset pico8 camera', function ()
          assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
        end)

        it('should call stop_bgm', function ()
          assert.spy(stage_state.stop_bgm).was_called(1)
          assert.spy(stage_state.stop_bgm).was_called_with(match.ref(state))
        end)

      end)

      describe('spawn_player_char', function ()

        setup(function ()
          spy.on(player_char, "spawn_at")
        end)

        teardown(function ()
          player_char.spawn_at:revert()
        end)

        it('should spawn the player character at the stage spawn location', function ()
          state:spawn_player_char()
          local player_char = state.player_char
          assert.is_not_nil(player_char)
          local spawn_position = state.curr_stage_data.spawn_location:to_center_position()

          -- interface
          assert.are_equal(spawn_position, player_char.position)
          -- we haven't initialized any map in busted, so the character is in the air and spawn_at detected this
          assert.are_equal(motion_states.airborne, player_char.motion_state)

          -- implementation
          assert.spy(player_char.spawn_at).was_called(1)
          assert.spy(player_char.spawn_at).was_called_with(match.ref(state.player_char), spawn_position)
        end)

      end)

      describe('(stage states added)', function ()

        before_each(function ()
          flow:add_gamestate(state)
          flow:add_gamestate(titlemenu)  -- for transition on reached goal
        end)

        after_each(function ()
          flow:init()
        end)

        describe('(stage state entered)', function ()

          before_each(function ()
            flow:_change_state(state)
            -- entering stage currently starts coroutine show_stage_title_async
            -- which will cause side effects when updating coroutines to test other
            -- async functions, so clear that now
            state.app:stop_all_coroutines()
          end)

          describe('update_camera', function ()

            before_each(function ()
              state.player_char.position = vector(12, 24)
            end)

            it('should move the camera to player position', function ()
              state:update_camera()
              assert.are_equal(vector(12, 24), state.camera_pos)
            end)

          end)

          describe('update', function ()

            setup(function ()
              stub(player_char, "update")
              stub(stage_state, "check_reached_goal")
              stub(stage_state, "update_camera")
            end)

            teardown(function ()
              player_char.update:revert()
              stage_state.check_reached_goal:revert()
              stage_state.update_camera:revert()
            end)

            after_each(function ()
              player_char.update:clear()
              stage_state.check_reached_goal:clear()
              stage_state.update_camera:clear()
            end)

            describe('(current substate is play)', function ()

              it('should call player_char:update, check_reached_goal and update_camera', function ()
                state.current_substate = stage_state.substates.play
                state:update()
                assert.spy(player_char.update).was_called(1)
                assert.spy(player_char.update).was_called_with(match.ref(state.player_char))
                assert.spy(stage_state.check_reached_goal).was_called(1)
                assert.spy(stage_state.check_reached_goal).was_called_with(match.ref(state))
                assert.spy(stage_state.update_camera).was_called(1)
                assert.spy(stage_state.update_camera).was_called_with(match.ref(state))      end)
            end)

            describe('(current substate is result)', function ()

              it('should call player_char:update, check_reached_goal and update_camera', function ()
                state.current_substate = stage_state.substates.result
                state:update()
                assert.spy(player_char.update).was_not_called()
                assert.spy(stage_state.check_reached_goal).was_not_called()
                assert.spy(stage_state.update_camera).was_not_called()
              end)

            end)

          end)  -- update

          describe('render', function ()

            setup(function ()
              stub(stage_state, "render_background")
              stub(stage_state, "render_stage_elements")
              stub(stage_state, "render_title_overlay")
            end)

            teardown(function ()
              stage_state.render_background:revert()
              stage_state.render_stage_elements:revert()
              stage_state.render_title_overlay:revert()
            end)

            after_each(function ()
              stage_state.render_background:clear()
              stage_state.render_stage_elements:clear()
              stage_state.render_title_overlay:clear()
            end)

            it('should reset camera, call render_background, render_stage_elements, render_title_overlay', function ()
              state:render()
              assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
              assert.spy(stage_state.render_background).was_called(1)
              assert.spy(stage_state.render_background).was_called_with(match.ref(state))
              assert.spy(stage_state.render_stage_elements).was_called(1)
              assert.spy(stage_state.render_stage_elements).was_called_with(match.ref(state))
              assert.spy(stage_state.render_title_overlay).was_called(1)
              assert.spy(stage_state.render_title_overlay).was_called_with(match.ref(state))
            end)

          end)  -- state.render

          describe('check_reached_goal', function ()

            setup(function ()
              stub(picosonic_app, "start_coroutine")
            end)

            teardown(function ()
              picosonic_app.start_coroutine:revert()
            end)

            -- start_coroutine is also called on stage enter (with show_stage_title_async)
            -- so we must clear call count *before* the first test
            before_each(function ()
              picosonic_app.start_coroutine:clear()
            end)

            describe('(before the goal)', function ()

              -- should be each
              before_each(function ()
                state.player_char.position = vector(state.curr_stage_data.goal_x - 1, 0)
                state:check_reached_goal()
              end)

              it('should not set has_reached_goal to true', function ()
                assert.is_false(state.has_reached_goal)
              end)

              it('should not start on_reached_goal_async', function ()
                local s = assert.spy(picosonic_app.start_coroutine)
                s.was_not_called()
              end)

            end)

            describe('(just on the goal)', function ()

              before_each(function ()
                state.player_char.position = vector(state.curr_stage_data.goal_x, 0)
                state:check_reached_goal()
              end)

              it('should set has_reached_goal to true', function ()
                assert.is_true(state.has_reached_goal)
              end)

              it('should start on_reached_goal_async', function ()
                local s = assert.spy(picosonic_app.start_coroutine)
                s.was_called(1)
                s.was_called_with(match.ref(state.app), stage_state.on_reached_goal_async, match.ref(state))
              end)

            end)

            describe('(after the goal)', function ()

              before_each(function ()
                state.player_char.position = vector(state.curr_stage_data.goal_x + 1, 0)
                state:check_reached_goal()
              end)

              it('should set has_reached_goal to true', function ()
                assert.is_true(state.has_reached_goal)
              end)

              it('should start on_reached_goal_async', function ()
                local s = assert.spy(picosonic_app.start_coroutine)
                s.was_called(1)
                s.was_called_with(match.ref(state.app), stage_state.on_reached_goal_async, match.ref(state))
              end)

            end)

          end)

          describe('state.on_reached_goal_async', function ()

            before_each(function ()
              state.app:start_coroutine(state.on_reached_goal_async, state)
            end)

            it('should set substate to result after 1 update', function ()
              -- update coroutines once to advance on_reached_goal_async
              state.app:update()
              -- state.app.coroutine_runner:update_coroutines()

              assert.are_equal(stage_state.substates.result, state.current_substate)
            end)

            it('should change gamestate to titlemenu after 1.0s + 1 update to apply the query next state', function ()
              for i = 1, stage_data.back_to_titlemenu_delay * state.app.fps + 1 do
                state.app:update()
              end
              assert.are_equal(':titlemenu', flow.curr_state.type)
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
              state:feedback_reached_goal()
              assert.spy(sfx_stub).was_called(1)
              assert.spy(sfx_stub).was_called_with(audio.sfx_ids.goal_reached)
            end)

          end)

          describe('back_to_titlemenu', function ()

            it('should change gamestate to titlemenu on next update', function ()
              state:back_to_titlemenu()
              flow:update()
              assert.are_equal(':titlemenu', flow.curr_state.type)
            end)

          end)

          describe('(no overlay labels)', function ()

            before_each(function ()
              clear_table(state.title_overlay.labels)
              state.app:start_coroutine(state.show_stage_title_async, state)
            end)

            it('show_stage_title_async should add a title label and remove it after global.show_stage_title_delay', function ()
              state.app:update()
              assert.are_equal(ui.label(state.curr_stage_data.title, vector(50, 30), colors.white), state.title_overlay.labels["title"])
              for i = 2, stage_data.show_stage_title_delay * state.app.fps do
                state.app:update()
              end
              assert.is_nil(state.title_overlay.labels["title"])
            end)

          end)

          describe('state render methods', function ()

            local map_stub
            local player_char_render_stub

            setup(function ()
              rectfill_stub = stub(_G, "rectfill")
              map_stub = stub(_G, "map")
              spy.on(stage_state, "render_environment")
              player_char_render_stub = stub(player_char, "render")
              title_overlay_draw_labels_stub = stub(ui.overlay, "draw_labels")
            end)

            teardown(function ()
              rectfill_stub:revert()
              map_stub:revert()
              state.render_environment:revert()
              player_char_render_stub:revert()
              title_overlay_draw_labels_stub:revert()
            end)

            after_each(function ()
              rectfill_stub:clear()
              map_stub:clear()
              state.render_environment:clear()
              player_char_render_stub:clear()
              title_overlay_draw_labels_stub:clear()
            end)

            it('render_title_overlay should call title_overlay:draw_labels', function ()
              state:render_title_overlay()
              assert.are_equal(vector.zero(), vector(pico8.camera_x, pico8.camera_y))
              assert.spy(title_overlay_draw_labels_stub).was_called(1)
              assert.spy(title_overlay_draw_labels_stub).was_called_with(state.title_overlay)
            end)

            it('render_background should reset camera position, call rectfill on the whole screen with stage background color', function ()
              state.camera_pos = vector(24, 13)
              state:render_background()
              assert.are_equal(vector(0, 0), vector(pico8.camera_x, pico8.camera_y))
              assert.spy(rectfill_stub).was_called(1)
              assert.spy(rectfill_stub).was_called_with(0, 0, 127, 127, state.curr_stage_data.background_color)
            end)

            it('render_stage_elements should set camera position, call map for environment and player_char:render', function ()
              state.camera_pos = vector(24, 13)
              state:render_stage_elements()
              assert.are_equal(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
              assert.spy(state.render_environment).was_called(1)
              assert.spy(state.render_environment).was_called_with(match.ref(state))
              assert.spy(player_char_render_stub).was_called(1)
              assert.spy(player_char_render_stub).was_called_with(match.ref(state.player_char))
            end)

            it('set_camera_offset_stage should set the pico8 camera so that it is centered on the camera position', function ()
              state.camera_pos = vector(24, 13)
              state:set_camera_offset_stage()
              assert.are_equal(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
            end)

            describe('(after set_camera_offset_stage)', function ()

              before_each(function ()
                state:set_camera_offset_stage()
              end)

              it('render_environment should call map', function ()
                state:render_environment()
                assert.spy(map_stub).was_called(1)
                assert.spy(map_stub).was_called_with(0, 0, 0, 0, state.curr_stage_data.width, state.curr_stage_data.height)
              end)

              it('render_player_char should call player_char:render', function ()
                state:render_player_char()
                assert.spy(player_char_render_stub).was_called(1)
                assert.spy(player_char_render_stub).was_called_with(match.ref(state.player_char))
              end)

            end)

          end)  -- state render methods

          describe('state audio methods', function ()

            after_each(function ()
              pico8.current_music = nil
            end)

            it('play_bgm should start level bgm', function ()
              state:play_bgm()
              assert.are_same({music=audio.music_pattern_ids.green_hill, fadems=0, channel_mask=0}, pico8.current_music)
            end)

            it('stop_bgm should stop level bgm if started, else do nothing', function ()
              state:stop_bgm()
              assert.is_nil(pico8.current_music)
              state:play_bgm()
              state:stop_bgm()
              assert.is_nil(pico8.current_music)
              state:play_bgm()
              state:stop_bgm(2.0)
              assert.is_nil(pico8.current_music)
            end)

          end)  -- state audio methods

          describe('on exit stage state to enter titlemenu state', function ()

            before_each(function ()
              flow:_change_state(titlemenu)
            end)

            it('player character should be nil', function ()
              assert.is_nil(state.player_char)
            end)

            it('title overlay should be empty', function ()
              assert.is_not_nil(state.title_overlay)
              assert.is_not_nil(state.title_overlay.labels)
              assert.is_true(is_empty(state.title_overlay.labels))
            end)

            describe('reenter stage state', function ()

              -- should be each
              before_each(function ()
                flow:_change_state(state)
              end)

              it('current substate should be play', function ()
                assert.are_equal(stage_state.substates.play, state.current_substate)
              end)

              it('player character should not be nil and respawned at the spawn location', function ()
                assert.is_not_nil(state.player_char)
                assert.are_equal(state.curr_stage_data.spawn_location:to_center_position(), state.player_char.position)
              end)

              it('should not have reached goal', function ()
                assert.is_false(state.has_reached_goal)
              end)

            end)

          end)  -- on exit stage state to enter titlemenu state

        end)  -- (enter stage state)

      end)  -- (stage states added)

    end)  -- (with instance)

  end)  -- (stage state)

end)
