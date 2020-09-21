require("test/bustedhelper")
local stage_state = require("ingame/stage_state")

local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local overlay = require("engine/ui/overlay")
local label = require("engine/ui/label")

local picosonic_app = require("application/picosonic_app_ingame")
local stage_data = require("data/stage_data")
local emerald = require("ingame/emerald")
local player_char = require("ingame/playercharacter")
local titlemenu = require("menu/titlemenu")
local audio = require("resources/audio")
local visual = require("resources/visual")

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

      it('init', function ()
        assert.are_same({
            ':stage',
            1,
            stage_state.substates.play,
            nil,
            false,
            {},
            vector.zero(),
            overlay(0)
          },
          {
            state.type,
            state.curr_stage_id,
            state.current_substate,
            state.player_char,
            state.has_reached_goal,
            state.emeralds,
            state.camera_pos,
            state.title_overlay
          })
      end)

      describe('on_enter', function ()

        setup(function ()
          stub(stage_state, "spawn_player_char")
          stub(picosonic_app, "start_coroutine")
          stub(stage_state, "play_bgm")
          stub(stage_state, "randomize_background_data")
          stub(stage_state, "spawn_emeralds")
        end)

        teardown(function ()
          stage_state.spawn_player_char:revert()
          picosonic_app.start_coroutine:revert()
          stage_state.play_bgm:revert()
          stage_state.randomize_background_data:revert()
          stage_state.spawn_emeralds:revert()
        end)

        after_each(function ()
          stage_state.spawn_player_char:clear()
          picosonic_app.start_coroutine:clear()
          stage_state.play_bgm:clear()
          stage_state.randomize_background_data:clear()
          stage_state.spawn_emeralds:clear()
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
          assert.are_same(vector:zero(), state.camera_pos)
        end)

        it('should call start_coroutine_method on show_stage_title_async', function ()
          local s = assert.spy(picosonic_app.start_coroutine)
          s.was_called(1)
          s.was_called_with(match.ref(state.app), stage_state.show_stage_title_async, match.ref(state))
        end)

        it('should call play_bgm', function ()
          assert.spy(state.play_bgm).was_called(1)
          assert.spy(state.play_bgm).was_called_with(match.ref(state))
        end)

        it('should call randomize_background_data', function ()
          assert.spy(state.randomize_background_data).was_called(1)
          assert.spy(state.randomize_background_data).was_called_with(match.ref(state))
        end)

        it('should call spawn_emeralds', function ()
          assert.spy(state.spawn_emeralds).was_called(1)
          assert.spy(state.spawn_emeralds).was_called_with(match.ref(state))
        end)

      end)

      describe('on_exit', function ()


        setup(function ()
          stub(overlay, "clear_labels")
          stub(picosonic_app, "stop_all_coroutines")
          stub(stage_state, "stop_bgm")
          -- we don't really mind spying on spawn_emeralds
          --  but we do not want to spend 0.5s finding all of them
          --  in before_each every time due to on_enter,
          --  so we stub this
          stub(stage_state, "spawn_emeralds")
        end)

        teardown(function ()
          overlay.clear_labels:revert()
          picosonic_app.stop_all_coroutines:revert()
          stage_state.stop_bgm:revert()
          stage_state.spawn_emeralds:revert()
        end)

        after_each(function ()
          overlay.clear_labels:clear()
          picosonic_app.stop_all_coroutines:clear()
          stage_state.stop_bgm:clear()
          stage_state.spawn_emeralds:clear()
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
          local s = assert.spy(overlay.clear_labels)
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
          -- we haven't initialized any map in busted, so the character is falling in the air and spawn_at detected this
          assert.are_equal(motion_states.falling, player_char.motion_state)

          -- implementation
          assert.spy(player_char.spawn_at).was_called(1)
          assert.spy(player_char.spawn_at).was_called_with(match.ref(state.player_char), spawn_position)
        end)

      end)

      describe('spawn_emeralds', function ()

        -- setup is too early, stage state will start afterward in before_each,
        --  and its on_enter will call spawn_emeralds, making it hard
        --  to test in isolation. Hence before_each.
        before_each(function ()
          local emerald_repr_sprite_id = visual.sprite_data_t.emerald.id_loc:to_sprite_id()
          mset(1, 1, emerald_repr_sprite_id)
          mset(2, 2, emerald_repr_sprite_id)
          mset(3, 3, emerald_repr_sprite_id)
        end)

        after_each(function ()
          pico8:clear_map()
        end)

        it('should clear all emerald tiles', function ()
          state:spawn_emeralds()
          assert.are_same({0, 0, 0},
            {
              mget(1, 1),
              mget(2, 2),
              mget(3, 3),
            })
        end)

        it('should spawn and store emerald objects for each removed emerald tile', function ()
          state:spawn_emeralds()
          assert.are_same({
            emerald(1, location(1, 1)),
            emerald(2, location(2, 2)),
            emerald(3, location(3, 3)),
            }, state.emeralds)
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

          setup(function ()
            -- we don't really mind spying on spawn_emeralds
            --  but we do not want to spend 0.5s finding all of them
            --  in before_each every time due to on_enter,
            --  so we stub this
            stub(stage_state, "spawn_emeralds")
          end)

          teardown(function ()
            stage_state.spawn_emeralds:revert()
          end)

          after_each(function ()
            stage_state.spawn_emeralds:clear()
          end)

          before_each(function ()
            flow:change_state(state)
            -- entering stage currently starts coroutine show_stage_title_async
            -- which will cause side effects when updating coroutines to test other
            -- async functions, so clear that now
            state.app:stop_all_coroutines()
          end)

          describe('update_camera', function ()

            before_each(function ()
              -- required for stage edge clamping
              -- we only need to mock width and height,
              --  normally we'd get full stage data as in stage_data.lua
              state.curr_stage_data = {
                width = 100,
                height = 20
              }
            end)

            it('should move the camera to player position', function ()
              state.player_char.position = vector(120, 80)

              state:update_camera()

              assert.are_same(vector(120, 80), state.camera_pos)
            end)

            it('should move the camera to player position, clamped (top-left)', function ()
              -- required for stage edge clamping
              state.player_char.position = vector(12, 24)

              state:update_camera()

              assert.are_same(vector(64, 64), state.camera_pos)
            end)

            it('should move the camera to player position, clamped (top-right)', function ()
              -- required for stage edge clamping
              state.player_char.position = vector(2000, 1000)

              state:update_camera()

              assert.are_same(vector(800-64, 160-64), state.camera_pos)
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

          describe('extend_spring', function ()

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

            it('should play a coroutine that replaces spring tile with extended spring tile until a certain time (only check no error)', function ()
              state:extend_spring(location(2, 0))
              assert.spy(picosonic_app.start_coroutine).was_called(1)
              assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_state.extend_spring_async, match.ref(state), location(2, 0))
            end)

          end)

          describe('check_emerald_pick_area', function ()

            before_each(function ()
              state.emeralds = {
                emerald(1, location(0, 0)),
                emerald(2, location(1, 0)),
                emerald(3, location(0, 1)),
              }
            end)

            it('should return nil when position is too far from all the emeralds', function ()
              assert.is_nil(state:check_emerald_pick_area(vector(12, 12)))
            end)

            it('should return emerald when position is close to that emerald (giving priority to lower index)', function ()
              assert.are_equal(state.emeralds[1], state:check_emerald_pick_area(vector(8, 4)))
            end)

          end)

          describe('character_pick_emerald', function ()

            before_each(function ()
              state.emeralds = {
                emerald(1, location(0, 0)),
                emerald(2, location(1, 0)),
                emerald(3, location(0, 1)),
              }
            end)

            it('should remove an emerald from the sequence', function ()
              state.emeralds = {
                emerald(1, location(0, 0)),
                emerald(2, location(1, 0)),
                emerald(3, location(0, 1)),
              }
              state:character_pick_emerald(state.emeralds[2])
              assert.are_same({emerald(1, location(0, 0)), emerald(3, location(0, 1))}, state.emeralds)
            end)

          end)

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
                assert.spy(picosonic_app.start_coroutine).was_not_called()
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
                assert.spy(picosonic_app.start_coroutine).was_called(1)
                assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_state.on_reached_goal_async, match.ref(state))
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
                assert.spy(picosonic_app.start_coroutine).was_called(1)
                assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_state.on_reached_goal_async, match.ref(state))
              end)

            end)

          end)

          describe('state.on_reached_goal_async', function ()

            local on_reached_goal_async_coroutine

            setup(function ()
              stub(stage_state, "back_to_titlemenu")
            end)

            teardown(function ()
              stage_state.back_to_titlemenu:revert()
            end)

            after_each(function ()
              stage_state.back_to_titlemenu:clear()
            end)

            before_each(function ()
              on_reached_goal_async_coroutine = cocreate(state.on_reached_goal_async)
            end)

            it('should set substate to result after 1 update', function ()
              -- update coroutines once to advance on_reached_goal_async
              coresume(on_reached_goal_async_coroutine, state)
              assert.are_equal(stage_state.substates.result, state.current_substate)
            end)

            -- this test is a bit extra, as it checks yield_delay_s's own validity
            -- however, it's useful to check that yield is done correctly (e.g. pass frames vs sec)
            -- and luassert spies are not good are identifying exact call order, so checking
            -- yield call itself is not too useful
            it('should query gamestate ":titlemenu" not earlier than after 1.0s', function ()
              for i = 1, stage_data.back_to_titlemenu_delay * state.app.fps - 1 do
                coresume(on_reached_goal_async_coroutine, state)
              end

              assert.spy(stage_state.back_to_titlemenu).was_not_called()
            end)

            it('should query gamestate ":titlemenu" after 1.0s', function ()
              -- hold back 1 frame to make sure function will be called exactly next frame
              for i = 1, stage_data.back_to_titlemenu_delay * state.app.fps - 1 do
                coresume(on_reached_goal_async_coroutine, state)
              end

              -- not called yet
              assert.spy(stage_state.back_to_titlemenu).was_not_called()

              coresume(on_reached_goal_async_coroutine, state)

              -- just called
              assert.spy(stage_state.back_to_titlemenu).was_called(1)
              assert.spy(stage_state.back_to_titlemenu).was_called_with(match.ref(state))
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

            setup(function ()
              stub(_G, "load")
            end)

            teardown(function ()
              load:revert()
            end)

            it('should laod cartridge: picosonic_titlemenu.p8', function ()
              state:back_to_titlemenu()
              assert.spy(load).was_called(1)
              assert.spy(load).was_called_with('picosonic_titlemenu.p8')
            end)

          end)

          describe('(no overlay labels)', function ()

            local on_show_stage_title_async

            before_each(function ()
              on_show_stage_title_async = cocreate(state.show_stage_title_async)
            end)

            after_each(function ()
              -- we don't stub overlay.add_label here, so we must clear any side effects
              clear_table(state.title_overlay.labels)
            end)

            it('show_stage_title_async should add a title label and remove it after stage_data.show_stage_title_delay seconds', function ()
              -- hold back last frame to check that label was added and didn't disappear yet
              for i = 1, stage_data.show_stage_title_delay * state.app.fps - 1 do
                coresume(on_show_stage_title_async, state)
              end
              assert.are_same(label(state.curr_stage_data.title, vector(50, 30), colors.white), state.title_overlay.labels["title"])

              -- reach last frame now to check if label just disappeared
              coresume(on_show_stage_title_async, state)

              assert.is_nil(state.title_overlay.labels["title"])
            end)

          end)

          describe('state render methods', function ()

            local player_char_render_stub

            setup(function ()
              stub(_G, "rectfill")
              stub(_G, "line")
              stub(_G, "map")
              spy.on(stage_state, "render_environment_midground")
              stub(stage_state, "render_environment_foreground")  -- stub will make us remember we don't cover it
              player_char_render_stub = stub(player_char, "render")
              title_overlay_draw_labels_stub = stub(overlay, "draw_labels")
            end)

            teardown(function ()
              rectfill:revert()
              line:revert()
              map:revert()
              stage_state.render_environment_midground:revert()
              stage_state.render_environment_foreground:revert()
              player_char_render_stub:revert()
              title_overlay_draw_labels_stub:revert()
            end)

            after_each(function ()
              rectfill:clear()
              line:clear()
              map:clear()
              stage_state.render_environment_midground:clear()
              stage_state.render_environment_foreground:clear()
              player_char_render_stub:clear()
              title_overlay_draw_labels_stub:clear()
            end)

            it('render_title_overlay should call title_overlay:draw_labels', function ()
              state:render_title_overlay()
              assert.are_same(vector.zero(), vector(pico8.camera_x, pico8.camera_y))
              assert.spy(title_overlay_draw_labels_stub).was_called(1)
              assert.spy(title_overlay_draw_labels_stub).was_called_with(state.title_overlay)
            end)

            it('render_background should reset camera position, call rectfill on the whole screen with stage background color', function ()
              state.camera_pos = vector(24, 13)
              state:render_background()
              assert.are_same(vector(0, 0), vector(pico8.camera_x, pico8.camera_y))

              -- more calls including rectfill and MANY line calls but we don't check background details, human tests are better for this
              -- assert.spy(line).was_called(771)
            end)

            it('render_stage_elements should set camera position, call map for environment and player_char:render', function ()
              state.camera_pos = vector(24, 13)
              state:render_stage_elements()
              assert.are_same(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
              assert.spy(state.render_environment_midground).was_called(1)
              assert.spy(state.render_environment_midground).was_called_with(match.ref(state))
              assert.spy(state.render_environment_foreground).was_called(1)
              assert.spy(state.render_environment_foreground).was_called_with(match.ref(state))
              assert.spy(player_char_render_stub).was_called(1)
              assert.spy(player_char_render_stub).was_called_with(match.ref(state.player_char))
            end)

            it('set_camera_offset_stage should set the pico8 camera so that it is centered on the camera position', function ()
              state.camera_pos = vector(24, 13)
              state:set_camera_offset_stage()
              assert.are_same(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
            end)

            describe('(after set_camera_offset_stage)', function ()

              before_each(function ()
                state:set_camera_offset_stage()
              end)

              it('render_environment_midground should call map', function ()
                state:render_environment_midground()
                assert.spy(map).was_called(1)
                assert.spy(map).was_called_with(0, 0, 0, 0, state.curr_stage_data.width, state.curr_stage_data.height, 1 << sprite_flags.midground)
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
              assert.are_same({music=audio.music_pattern_ids.green_hill, fadems=0, channel_mask=(1 << 0) + (1 << 2) + (1 << 3)}, pico8.current_music)
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
              flow:change_state(titlemenu)
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
                -- spawn_emeralds has been stubbed in this context,
                --  so this won't slow down every test
                flow:change_state(state)
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
