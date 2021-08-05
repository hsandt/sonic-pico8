require("test/bustedhelper_stage_clear")
-- we should only need common_stage_clear_state required in bustedhelper_stage_clear_state,
--  but exceptionally we have titlemenu-related tests in this file, so we need stuff
--  like fun_helper (we should actually isolate tests and reverse cross-testing to itests,
--  whether complex tests done via busted but done in dedicated files, or simulation tests)
require("common_titlemenu")
require("resources/visual_ingame_addon")
require("resources/visual_stage_clear_addon")

local stage_clear_state = require("stage_clear/stage_clear_state")

local coroutine_runner = require("engine/application/coroutine_runner")
local flow = require("engine/application/flow")
local animated_sprite = require("engine/render/animated_sprite")
local postprocess = require("engine/render/postprocess")
local sprite_data = require("engine/render/sprite_data")
local overlay = require("engine/ui/overlay")

local picosonic_app = require("application/picosonic_app_stage_clear")
local base_stage_state = require("ingame/base_stage_state")
local goal_plate = require("ingame/goal_plate")
local titlemenu = require("menu/titlemenu")
local visual = require("resources/visual_common")
local visual_stage = require("resources/visual_stage")
local tile_repr = require("test_data/tile_representation")
local tile_test_data = require("test_data/tile_test_data")

describe('stage_clear_state', function ()

  describe('static members', function ()

    it('type is ":stage_clear"', function ()
      assert.are_equal(':stage_clear', stage_clear_state.type)
    end)

  end)

  describe('(with instance)', function ()

    local state
    local titlemenu_state

    before_each(function ()
      local app = picosonic_app()
      state = stage_clear_state()
      -- no need to register gamestate properly, just add app member to pass tests
      state.app = app

      -- exceptionally we also need titlemenu state
      titlemenu_state = titlemenu()
      titlemenu_state.app = app
    end)

    describe('init', function ()

      setup(function ()
        spy.on(base_stage_state, "init")
      end)

      teardown(function ()
        base_stage_state.init:revert()
      end)

      after_each(function ()
        base_stage_state.init:clear()
      end)

      it('should call base constructor', function ()
        assert.spy(base_stage_state.init).was_called(1)
        assert.spy(base_stage_state.init).was_called_with(match.ref(state))
      end)

      it('should initialize members', function ()
        assert.are_same({
            ':stage_clear',
            1,
            0,
            postprocess(),
            overlay(),
            {},
            0,
            {},
            {},
          },
          {
            state.type,
            state.curr_stage_id,
            state.phase,
            state.postproc,
            state.result_overlay,
            state.picked_emerald_numbers_set,
            state.picked_emerald_count,
            state.result_show_emerald_set_by_number,
            state.result_emerald_brightness_levels
          })
      end)

    end)

    describe('on_enter', function ()

      setup(function ()
        stub(stage_clear_state, "restore_picked_emerald_data")
        stub(_G, "reload")
        stub(stage_clear_state, "scan_current_region_to_spawn_objects")
        stub(picosonic_app, "start_coroutine")
      end)

      teardown(function ()
        stage_clear_state.restore_picked_emerald_data:revert()
        reload:revert()
        stage_clear_state.scan_current_region_to_spawn_objects:revert()
        picosonic_app.start_coroutine:revert()
      end)

      after_each(function ()
        stage_clear_state.restore_picked_emerald_data:clear()
        reload:clear()
        stage_clear_state.scan_current_region_to_spawn_objects:clear()
        picosonic_app.start_coroutine:clear()
      end)

      before_each(function ()
        state:on_enter()
      end)

      it('should call restore_picked_emerald_data', function ()
        assert.spy(state.restore_picked_emerald_data).was_called(1)
        assert.spy(state.restore_picked_emerald_data).was_called_with(match.ref(state))
      end)

      it('should hardcode set camera position', function ()
        -- uses init_position under the hood, but check result directly to simplify
        assert.are_equal(vector(3376, 328), state.camera.position)
        assert.are_equal(328, state.camera.base_position.y)
      end)

      it('should hardcode set loaded_map_region_coords', function ()
        assert.are_equal(vector(3, 1), state.loaded_map_region_coords)
      end)

      it('should call reload for stage1, map 31 (hardcoded)', function ()
        assert.spy(reload).was_called(1)
        assert.spy(reload).was_called_with(0x2000, 0x2000, 0x1000, "data_stage1_31.p8")
      end)

      it('should call scan_current_region_to_spawn_objects', function ()
        assert.spy(state.scan_current_region_to_spawn_objects).was_called(1)
        assert.spy(state.scan_current_region_to_spawn_objects).was_called_with(match.ref(state))
      end)

      it('should call start_coroutine_method on play_stage_clear_sequence_async', function ()
        local s = assert.spy(picosonic_app.start_coroutine)
        s.was_called(1)
        s.was_called_with(match.ref(state.app), stage_clear_state.play_stage_clear_sequence_async, match.ref(state))
      end)

    end)

    describe('spawn_goal_plate_at', function ()

      setup(function ()
        spy.on(animated_sprite, "play")
      end)

      teardown(function ()
        animated_sprite.play:revert()
      end)

      after_each(function ()
        animated_sprite.play:clear()
      end)

      it('should spawn and store goal plate core at global location', function ()
        state:spawn_goal_plate_at(location(1, 33))

        local gp = goal_plate(location(1, 33))
        gp.anim_spr:play("sonic")

        assert.are_same(gp, state.goal_plate)
      end)

      it('should show sonic face of goal plate by playing corresponding animation', function ()
        state:spawn_goal_plate_at(location(1, 33))

        -- goal plate creation defaults to "goal" animation so play is actually called twice,
        --  but we only care about last call
        assert.spy(animated_sprite.play).was_called(2)
        assert.spy(animated_sprite.play).was_called_with(match.ref(state.goal_plate.anim_spr), "sonic")
      end)

    end)

    describe('scan_current_region_to_spawn_objects', function ()

      setup(function ()
        stub(stage_clear_state, "spawn_goal_plate_at")
      end)

      teardown(function ()
        stage_clear_state.spawn_goal_plate_at:revert()
      end)

      -- setup is too early, stage state will start afterward in before_each,
      --  and its on_enter will call scan_current_region_to_spawn_objects, making it hard
      --  to test in isolation. Hence before_each.
      before_each(function ()
        -- we're not using tile_test_data.setup here
        --  (since objects are checked directly by id, not using collision data)
        --  so don't use mock_mset
        mset(1, 1, visual.goal_plate_base_id)
        mset(2, 2, visual.goal_plate_base_id)
        mset(3, 3, visual.goal_plate_base_id)

        -- mock stage dimensions, not too big to avoid test too long
        --  (just 2 regions so we can check that location conversion works)
        state.curr_stage_data = {
          tile_width = 128,     -- 1 region per row
          tile_height = 32 * 2  -- 2 regions per column
        }

        state.loaded_map_region_coords = vector(0, 1)  -- will add 32 to each j
      end)

      after_each(function ()
        stage_clear_state.spawn_goal_plate_at:clear()

        pico8:clear_map()
      end)

      it('should call spawn_goal_plate_at global location', function ()
        state:scan_current_region_to_spawn_objects()

        assert.spy(stage_clear_state.spawn_goal_plate_at).was_called(3)
        assert.spy(stage_clear_state.spawn_goal_plate_at).was_called_with(match.ref(state), location(1 + map_region_tile_width * 3, 1 + map_region_tile_height * 1))
      end)

    end)

    describe('get_map_region_filename', function ()

      it('(1, 0) => "data_stage1_10.p8"', function ()
        -- hardcoded to stage 1
        assert.are_equal("data_stage1_10.p8", state:get_map_region_filename(1, 0))
      end)

    end)

    describe('(stage states added)', function ()

      before_each(function ()
        flow:add_gamestate(state)
        flow:add_gamestate(titlemenu_state)  -- for transition on reached goal
      end)

      after_each(function ()
        flow:init()
      end)

      describe('(stage state entered)', function ()

        setup(function ()
          -- restore_picked_emerald_data relies on peek which will find nil memory if not set
          -- so stub it
          stub(stage_clear_state, "restore_picked_emerald_data")

          -- we don't really mind spying on scan_current_region_to_spawn_objects
          --  but we do not want to spend several seconds finding all of them
          --  in before_each every time due to on_enter just for tests,
          --  so we stub this
          stub(stage_clear_state, "scan_current_region_to_spawn_objects")
        end)

        teardown(function ()
          stage_clear_state.scan_current_region_to_spawn_objects:revert()
          stage_clear_state.restore_picked_emerald_data:revert()
        end)

        after_each(function ()
          stage_clear_state.scan_current_region_to_spawn_objects:clear()
          stage_clear_state.restore_picked_emerald_data:clear()
        end)

        before_each(function ()
          flow:change_state(state)
          -- entering stage currently starts coroutine play_stage_clear_sequence_async
          -- which will cause side effects when updating coroutines to test other
          -- async functions, so clear that now
          state.app:stop_all_coroutines()
        end)

        describe('update', function ()

          setup(function ()
          end)

          teardown(function ()
          end)

          before_each(function ()
          end)

          after_each(function ()
          end)

        end)  -- update

        describe('render', function ()

          setup(function ()
            stub(visual_stage, "render_background")
            stub(stage_clear_state, "render_stage_elements")
            stub(stage_clear_state, "render_overlay")
            stub(stage_clear_state, "render_emeralds")
          end)

          teardown(function ()
            visual_stage.render_background:revert()
            stage_clear_state.render_stage_elements:revert()
            stage_clear_state.render_overlay:revert()
            stage_clear_state.render_emeralds:revert()
          end)

          after_each(function ()
            visual_stage.render_background:clear()
            stage_clear_state.render_stage_elements:clear()
            stage_clear_state.render_overlay:clear()
            stage_clear_state.render_emeralds:clear()
          end)

          it('(phase 0) should call render_background, render_stage_elements, render_overlay, render_emeralds', function ()
            state.phase = 0

            state:render()

            assert.spy(visual_stage.render_background).was_called(1)
            assert.spy(visual_stage.render_background).was_called_with(vector(3376, 328))
            assert.spy(stage_clear_state.render_stage_elements).was_called(1)
            assert.spy(stage_clear_state.render_stage_elements).was_called_with(match.ref(state))
            assert.spy(stage_clear_state.render_emeralds).was_called(1)
            assert.spy(stage_clear_state.render_emeralds).was_called_with(match.ref(state))
            assert.spy(stage_clear_state.render_overlay).was_called(1)
            assert.spy(stage_clear_state.render_overlay).was_called_with(match.ref(state))
          end)


          it('should call render_background, render_stage_elements, render_overlay, render_emeralds', function ()
            state.phase = 1

            state:render()

            assert.spy(stage_clear_state.render_emeralds).was_called(1)
            assert.spy(stage_clear_state.render_emeralds).was_called_with(match.ref(state))
            assert.spy(stage_clear_state.render_overlay).was_called(1)
            assert.spy(stage_clear_state.render_overlay).was_called_with(match.ref(state))
          end)

        end)  -- state.render

        describe('play_stage_clear_sequence_async', function ()

          -- removed actual tests, too hard to maintain
          -- instead, just run it and see if it crashes

          local corunner

          before_each(function ()
            state.goal_plate = goal_plate(location(100, 0))
            state.spawned_emerald_locations = {1, 2, 3, 4, 5, 6, 7, 8}

            corunner = coroutine_runner()
            corunner:start_coroutine(stage_clear_state.play_stage_clear_sequence_async, state)
          end)

          it('should not crash with a few emeralds', function ()
            -- emerald bitset: 0b10100110
            pico8.poked_addresses[0x5d00] = 0xa6

            -- a time long enough to cover other async methods like assess_result_async
            for i = 1, 1000 do
              corunner:update_coroutines()
            end
          end)

          it('should not crash with all emeralds', function ()
            -- emerald bitset: 0b11111111
            pico8.poked_addresses[0x5d00] = 0xff

            -- a time long enough to cover other async methods like assess_result_async
            for i = 1, 1000 do
              corunner:update_coroutines()
            end
          end)

        end)

        describe('render_stage_elements', function ()

          setup(function ()
            stub(stage_clear_state, "render_environment_midground")
            stub(stage_clear_state, "render_goal_plate")
            stub(stage_clear_state, "render_environment_foreground")
          end)

          teardown(function ()
            stage_clear_state.render_environment_midground:revert()
            stage_clear_state.render_goal_plate:revert()
            stage_clear_state.render_environment_foreground:revert()
          end)

          after_each(function ()
            stage_clear_state.render_environment_midground:clear()
            stage_clear_state.render_goal_plate:clear()
            stage_clear_state.render_environment_foreground:clear()
          end)

          it('should call render methods on everything in the stage', function ()
            state:render_stage_elements()
            assert.spy(state.render_environment_midground).was_called(1)
            assert.spy(state.render_environment_midground).was_called_with(match.ref(state))
            assert.spy(state.render_goal_plate).was_called(1)
            assert.spy(state.render_goal_plate).was_called_with(match.ref(state))
            assert.spy(state.render_environment_foreground).was_called(1)
            assert.spy(state.render_environment_foreground).was_called_with(match.ref(state))
          end)

        end)

        describe('render_overlay', function ()

          setup(function ()
            stub(overlay, "draw")
          end)

          teardown(function ()
            overlay.draw:revert()
          end)

          after_each(function ()
            overlay.draw:clear()
          end)

          it('should reset camera', function ()
            state:render_overlay()
            assert.are_same(vector.zero(), vector(pico8.camera_x, pico8.camera_y))
          end)

          it('should call result_overlay:draw', function ()
            state:render_overlay()
            assert.spy(overlay.draw).was_called(1)
            assert.spy(overlay.draw).was_called_with(match.ref(state.result_overlay))
          end)

        end)

        describe('render_goal_plate', function ()

          setup(function ()
            stub(stage_clear_state, "set_camera_with_origin")
            stub(goal_plate, "render")
          end)

          teardown(function ()
            stage_clear_state.set_camera_with_origin:revert()
            goal_plate.render:revert()
          end)

          after_each(function ()
            stage_clear_state.set_camera_with_origin:clear()
            goal_plate.render:clear()
          end)

          it('(goal plate must be found) should call set_camera_with_origin and goal_plate:render', function ()
            state.goal_plate = goal_plate(location(2, 33))

            state:render_goal_plate()

            assert.spy(stage_clear_state.set_camera_with_origin).was_called(1)
            assert.spy(stage_clear_state.set_camera_with_origin).was_called_with(match.ref(state))
            assert.spy(goal_plate.render).was_called(1)
            assert.spy(goal_plate.render).was_called_with(match.ref(state.goal_plate))
          end)

        end)

        describe('(with tile_test_data)', function ()

          setup(function ()
            tile_test_data.setup()

            stub(stage_clear_state, "set_camera_with_origin")
            stub(stage_clear_state, "set_camera_with_region_origin")
            stub(sprite_data, "render")
            stub(_G, "spr")
            stub(_G, "map")
          end)

          teardown(function ()
            tile_test_data.teardown()

            stage_clear_state.set_camera_with_origin:revert()
            stage_clear_state.set_camera_with_region_origin:revert()
            sprite_data.render:revert()
            spr:revert()
            map:revert()
          end)

          before_each(function ()
            -- 2 midground tiles on screen, 1 outside when camera is at (0, 0)
            mock_mset(0, 0, tile_repr.spring_up_repr_tile_id)
            mock_mset(3, 0, tile_repr.spring_up_repr_tile_id)
            mock_mset(9, 0, tile_repr.spring_up_repr_tile_id)
            -- 1 undefined tile onscreen (it's foreground hiding leaf in PICO-8,
            --  but what matters here is that midground flag is not set)
            mock_mset(5, 0, 46)
            -- foreground tile to test foreground layer
            mock_mset(0, 1, tile_repr.grass_top_decoration1)
          end)

          after_each(function ()
            pico8:clear_map()

            stage_clear_state.set_camera_with_origin:clear()
            stage_clear_state.set_camera_with_region_origin:clear()
            sprite_data.render:clear()
            spr:clear()
            map:clear()
          end)

        end)  -- (with tile_test_data)

        describe('extra render methods (no-crash only)', function ()

          it('render_emeralds should not crash', function ()
            state:render_emeralds()
          end)

        end)

        describe('on exit stage state to enter titlemenu state (we actually change cartridge)', function ()

          before_each(function ()
            flow:change_state(titlemenu_state)
          end)

          it('player character should be nil', function ()
            assert.is_nil(state.player_char)
          end)

          it('result overlay should be empty', function ()
            assert.is_not_nil(state.result_overlay)
            assert.is_not_nil(state.result_overlay.drawables_seq)
            assert.is_true(is_empty(state.result_overlay.drawables_seq))
          end)

        end)  -- on exit stage state to enter titlemenu state

        -- unlike above, we test on_exit method itself here

        -- COMMENTED OUT to strip characters since we just load new cartridges and never exit
        -- the stage_clear state
        --[[
        describe('on_exit', function ()

          setup(function ()
            stub(overlay, "clear_drawables")
            stub(picosonic_app, "stop_all_coroutines")
          end)

          teardown(function ()
            overlay.clear_drawables:revert()
            picosonic_app.stop_all_coroutines:revert()
          end)

          after_each(function ()
            overlay.clear_drawables:clear()
          end)

          before_each(function ()
            -- another before_each called stop_all_coroutines,
            --  so we must clear the count
            picosonic_app.stop_all_coroutines:clear()

            state:on_exit()
          end)

          it('should stop all the coroutines', function ()
            assert.spy(picosonic_app.stop_all_coroutines).was_called(1)
            assert.spy(picosonic_app.stop_all_coroutines).was_called_with(match.ref(state.app))
          end)

          it('should clear the player character', function ()
            assert.is_nil(state.player_char)
          end)

          it('should call clear all drawables', function ()
            assert.spy(overlay.clear_drawables).was_called(1)
            assert.spy(overlay.clear_drawables).was_called_with(match.ref(state.result_overlay))
          end)

          it('should reset pico8 camera', function ()
            assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
          end)

        end)
        --]]

      end)  -- (stage state entered)

    end)  -- (stage states added)

  end)  -- (with instance)

end)
