require("test/bustedhelper_ingame")
-- we should only need common_ingame required in bustedhelper_ingame,
--  but exceptionally we have titlemenu-related tests in this file, so we need stuff
--  like fun_helper (we should actually isolate tests and reverse cross-testing to itests,
--  whether complex tests done via busted but done in dedicated files, or simulation tests)
require("common_titlemenu")
require("resources/visual_ingame_addon")

local stage_state = require("ingame/stage_state")

local coroutine_runner = require("engine/application/coroutine_runner")
local gameapp = require("engine/application/gameapp")
local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local location_rect = require("engine/core/location_rect")
local animated_sprite = require("engine/render/animated_sprite")
local sprite_data = require("engine/render/sprite_data")
local overlay = require("engine/ui/overlay")
local label = require("engine/ui/label")

local picosonic_app = require("application/picosonic_app_ingame")
local camera_data = require("data/camera_data")
local stage_data = require("data/stage_data")
local camera_class = require("ingame/camera")
local emerald = require("ingame/emerald")
local emerald_fx = require("ingame/emerald_fx")
local goal_plate = require("ingame/goal_plate")
local player_char = require("ingame/playercharacter")
local titlemenu = require("menu/titlemenu")
local audio = require("resources/audio")
local visual = require("resources/visual_common")
local tile_repr = require("test_data/tile_representation")
local tile_test_data = require("test_data/tile_test_data")

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
            {},
            {},
            {},
            {},
            camera_class(),
            overlay(),
            -- result UI animation only (async methods changing this won't be fully tested)
            overlay(),
            false,
            {},
            -- result UI animation end
            nil,
            -- itest only
            true,
          },
          {
            state.type,
            state.curr_stage_id,
            state.current_substate,
            state.player_char,
            state.has_player_char_reached_goal,
            state.spawned_emerald_locations,
            state.emeralds,
            state.picked_emerald_numbers_set,
            state.emerald_pick_fxs,
            state.palm_tree_leaves_core_global_locations,
            state.camera,
            state.title_overlay,
            -- result UI animation only (async methods changing this won't be fully tested)
            state.result_overlay,
            state.result_show_emerald_cross_base,
            state.result_emerald_cross_palette_swap_table,
            -- result UI animation end
            state.loaded_map_region_coords,
            -- itest only
            state.enable_spawn_objects,
          })
      end)

      describe('on_enter', function ()

        setup(function ()
          stub(stage_state, "spawn_player_char")
          stub(picosonic_app, "start_coroutine")
          stub(stage_state, "play_bgm")
          stub(stage_state, "reload_bgm")
          stub(stage_state, "randomize_background_data")
          stub(stage_state, "spawn_objects_in_all_map_regions")
          stub(camera_class, "setup_for_stage")
          stub(stage_state, "check_reload_map_region")
          stub(_G, "reload")
        end)

        teardown(function ()
          stage_state.spawn_player_char:revert()
          picosonic_app.start_coroutine:revert()
          stage_state.play_bgm:revert()
          stage_state.reload_bgm:revert()
          stage_state.randomize_background_data:revert()
          stage_state.spawn_objects_in_all_map_regions:revert()
          camera_class.setup_for_stage:revert()
          stage_state.check_reload_map_region:revert()
          reload:revert()
        end)

        after_each(function ()
          stage_state.spawn_player_char:clear()
          picosonic_app.start_coroutine:clear()
          stage_state.play_bgm:clear()
          stage_state.reload_bgm:clear()
          stage_state.randomize_background_data:clear()
          stage_state.spawn_objects_in_all_map_regions:clear()
          camera_class.setup_for_stage:clear()
          stage_state.check_reload_map_region:clear()
          reload:clear()
        end)

        before_each(function ()
          state:on_enter()
        end)

        it('should call spawn_objects_in_all_map_regions', function ()
          assert.spy(state.spawn_objects_in_all_map_regions).was_called(1)
          assert.spy(state.spawn_objects_in_all_map_regions).was_called_with(match.ref(state))
        end)

        it('should call setup_for_stage on camera with current stage data', function ()
          assert.spy(camera_class.setup_for_stage).was_called(1)
          assert.spy(camera_class.setup_for_stage).was_called_with(match.ref(state.camera), state.curr_stage_data)
        end)

        it('should call check_reload_map_region', function ()
          assert.spy(state.check_reload_map_region).was_called(1)
          assert.spy(state.check_reload_map_region).was_called_with(match.ref(state))
        end)

        it('should enter the play substates', function ()
          assert.are_equal(stage_state.substates.play, state.current_substate)
        end)

        it('should call spawn_player_char', function ()
          assert.spy(stage_state.spawn_player_char).was_called(1)
          assert.spy(stage_state.spawn_player_char).was_called_with(match.ref(state))
        end)

        it('should assign spawned player char to camera target', function ()
          assert.are_equal(state.player_char, state.camera.target_pc)
        end)

        it('should set has_player_char_reached_goal to false', function ()
          assert.is_false(state.has_player_char_reached_goal)
        end)

        it('should call start_coroutine_method on show_stage_title_async', function ()
          local s = assert.spy(picosonic_app.start_coroutine)
          s.was_called(1)
          s.was_called_with(match.ref(state.app), stage_state.show_stage_title_async, match.ref(state))
        end)

        it('should call reload_bgm', function ()
          assert.spy(state.reload_bgm).was_called(1)
          assert.spy(state.reload_bgm).was_called_with(match.ref(state))
        end)

        it('should call play_bgm', function ()
          assert.spy(state.play_bgm).was_called(1)
          assert.spy(state.play_bgm).was_called_with(match.ref(state))
        end)

        it('should call randomize_background_data', function ()
          assert.spy(state.randomize_background_data).was_called(1)
          assert.spy(state.randomize_background_data).was_called_with(match.ref(state))
        end)

        it('should reload background sprites to overwrite collision mask sprites (spritesheet top part)', function ()
          assert.spy(reload).was_called(1)
          assert.spy(reload).was_called_with(0x0, 0x0, 0x600, "data_stage1_runtime.p8")
        end)

      end)

      describe('is_tile_in_area', function ()

        it('should return true for tile in one of the entrance areas', function ()
          -- this depends on stage_data.for_stage[1].loop_entrance_areas content and
          --  location_rect:contains correctness
          assert.is_true(state:is_tile_in_area(location(4, 4),
            {location_rect(0, 0, 2, 2), location_rect(4, 4, 6, 6)}))
        end)

        it('should return false for tile not in any of the entrance areas', function ()
          -- this depends on stage_data.for_stage[1].loop_entrance_areas content and
          --  location_rect:contains correctness
          assert.is_true(state:is_tile_in_area(location(5, 5),
            {location_rect(0, 0, 2, 2), location_rect(4, 4, 6, 6)}))
        end)

      end)

      describe('is_tile_in_loop_entrance', function ()

        before_each(function ()
          -- customize loop areas locally. We are redefining a table so that won't affect
          --  the original data table in stage_data.lua. To simplify we don't redefine everything,
          --  but if we need to for the tests we'll just add the missing members
          state.curr_stage_data = {
            loop_entrance_areas = {location_rect(1, 0, 3, 4)}
          }
        end)

        -- we wrote those tests before extracting is_tile_in_area and it's simpler
        --  to test result than stubbing is_tile_in_area with a dummy function anyway,
        --  so we keep direct testing despite overlapping is_tile_in_area utests above

        it('should return true for tile in one of the entrance areas, but not the top-left corner reserved to trigger', function ()
          assert.is_true(state:is_tile_in_loop_entrance(location(2, 0)))
        end)

        it('should return false for tile just on the top-left corner entrance trigger (and not inside another area excluding trigger)', function ()
          assert.is_false(state:is_tile_in_loop_entrance(location(1, 0)))
        end)

        it('should return false for tile not in any of the entrance areas', function ()
          assert.is_false(state:is_tile_in_loop_entrance(location(0, 0)))
        end)

      end)

      describe('is_tile_in_loop_exit', function ()

        before_each(function ()
          -- customize loop areas locally. We are redefining a table so that won't affect
          --  the original data table in stage_data.lua. To simplify we don't redefine everything,
          --  but if we need to for the tests we'll just add the missing members
          state.curr_stage_data = {
            loop_exit_areas = {location_rect(-1, 0, 0, 2)}
          }
        end)

        it('should return true for tile in one of the exit areas, but not the top-right corner reserved to trigger', function ()
          assert.is_true(state:is_tile_in_loop_exit(location(0, 1)))
        end)

        it('should return false for tile just on the top-right corner exit trigger (and not inside another area excluding trigger)', function ()
          assert.is_false(state:is_tile_in_loop_exit(location(0, 0)))
        end)

        it('should return false for tile not in any of the exit areas', function ()
          assert.is_false(state:is_tile_in_loop_exit(location(0, -1)))
        end)

      end)

      describe('spawn_emerald_at', function ()

        it('should store emerald global location', function ()
          state:spawn_emerald_at(location(1, 33))

          assert.are_same({
            location(1, 33),
          }, state.spawned_emerald_locations)
        end)

        it('should spawn and store emerald objects for each emerald tile', function ()
          state:spawn_emerald_at(location(1, 33))

          assert.are_same({
            emerald(1, location(1, 33)),
          }, state.emeralds)
        end)

      end)

      describe('spawn_palm_tree_leaves', function ()

        it('should store palm tree leaves core global location', function ()
          state:spawn_palm_tree_leaves_at(location(1, 33))

          assert.are_same({
            location(1, 33),
          }, state.palm_tree_leaves_core_global_locations)
        end)

      end)

      describe('scan_current_region_to_spawn_objects', function ()

        local dummy_callback = spy.new(function (self, global_loc) end)

        setup(function ()
          stub(stage_state, "get_spawn_object_callback", function (self, tile_id)
            if tile_id == 21 then
              return dummy_callback
            end
          end)
        end)

        teardown(function ()
          stage_state.get_spawn_object_callback:revert()
        end)

        -- setup is too early, stage state will start afterward in before_each,
        --  and its on_enter will call scan_current_region_to_spawn_objects, making it hard
        --  to test in isolation. Hence before_each.
        before_each(function ()
          -- we're not using tile_test_data.setup here
          --  (since objects are checked directly by id, not using collision data)
          --  so don't use mock_mset
          mset(1, 1, 21)
          mset(2, 2, 21)
          mset(3, 3, 21)

          -- mock stage dimensions, not too big to avoid test too long
          --  (just 2 regions so we can check that location conversion works)
          state.curr_stage_data = {
            tile_width = 128,     -- 1 region per row
            tile_height = 32 * 2  -- 2 regions per column
          }

          state.loaded_map_region_coords = vector(0, 1)  -- will add 32 to each j
        end)

        after_each(function ()
          dummy_callback:clear()

          pico8:clear_map()
        end)

        it('should call spawn object callbacks for recognized representative tiles', function ()
          state:scan_current_region_to_spawn_objects()

          assert.spy(dummy_callback).was_called(3)
          assert.spy(dummy_callback).was_called_with(match.ref(state), location(1, 1 + 32), 21)
        end)

      end)

      describe('get_map_region_filename', function ()

        it('stage 2, (1, 0) => "data_stage2_10.p8"', function ()
          state.curr_stage_id = 2
          assert.are_equal("data_stage2_10.p8", state:get_map_region_filename(1, 0))
        end)

      end)

      describe('get_region_grid_dimensions', function ()

        it('should return the number of regions per row, per column"', function ()
          state.curr_stage_data = {
            tile_width = 250,     -- not exactly 256 to test ceiling to 2 regions per row
            tile_height = 32 * 3  -- 3 regions per column
          }

          assert.are_same({2, 3}, {state:get_region_grid_dimensions()})
        end)

      end)

      describe('get_map_region_coords', function ()

        before_each(function ()
          -- required for stage edge clamping
          -- we only need to mock width and height,
          --  normally we'd get full stage data as in stage_data.lua
          state.curr_stage_data = {
            tile_width = 250,     -- not exactly 256 to test ceiling to 2 regions per row
            tile_height = 32 * 3  -- 3 regions per column
          }
        end)

        it('should return (0, 0) in region (0, 0), even when close to top and left edges (limit)', function ()
          -- X  |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0, 0), state:get_map_region_coords(vector(0, 0)))
        end)

        it('should return (0, 0) in region (0, 0) right in the middle', function ()
          --    |
          --  X |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0, 0), state:get_map_region_coords(vector(512, 128)))
        end)

        it('should return (0.5, 0) in region (0, 0) near right edge', function ()
          --    |
          --   X|
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0.5, 0), state:get_map_region_coords(vector(1020, 128)))
        end)

        it('should return (0.5, 0) in region (1, 0) near left edge', function ()
          --    |
          --    |X
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0.5, 0), state:get_map_region_coords(vector(1030, 128)))
        end)

        it('should return (1, 0) in region (1, 0) right in the middle', function ()
          --    |
          --    | X
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(1, 0), state:get_map_region_coords(vector(1536, 128)))
        end)

        it('should return (1, 0) in region (1, 0) even when close to top and right edges (limit)', function ()
          assert.are_equal(vector(1, 0), state:get_map_region_coords(vector(2047, 0)))
        end)

        it('should return (0, 0.5) in region (0, 0), near bottom edge', function ()
          --    |
          --    |
          --  X |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0, 0.5), state:get_map_region_coords(vector(0, 250)))
        end)

        it('should return (0.5, 0.5) in region (0, 0), near bottom and right edges (cross)', function ()
          --    |
          --    |
          --   X|
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0.5, 0.5), state:get_map_region_coords(vector(1020, 250)))
        end)

        it('should return (0.5, 0.5) in region (1, 0), near bottom and left edges (cross)', function ()
          --    |
          --    |
          --    |X
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0.5, 0.5), state:get_map_region_coords(vector(1030, 250)))
        end)

        it('should return (1, 0.5) in region (1, 0), near bottom edge', function ()
          --    |
          --    |
          --    | X
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(1, 0.5), state:get_map_region_coords(vector(1536, 250)))
        end)

        it('should return (1, 0.5) in region (1, 0), near bottom edge, even when close to right edge (limit)', function ()
          --    |
          --    |
          --    |  X
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(1, 0.5), state:get_map_region_coords(vector(2047, 250)))
        end)

        it('should return (0, 0.5) in region (0, 1), near top edge', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --  X |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0, 0.5), state:get_map_region_coords(vector(0, 260)))
        end)

        it('should return (0.5, 0.5) in region (0, 1), near top and right edges (cross)', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --   X|
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0.5, 0.5), state:get_map_region_coords(vector(1020, 260)))
        end)

        it('should return (0.5, 0.5) in region (1, 1), near top and left edges (cross)', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --    |X
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0.5, 0.5), state:get_map_region_coords(vector(1030, 260)))
        end)

        it('should return (1, 0.5) in region (1, 1), near top edge', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --    | X
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(1, 0.5), state:get_map_region_coords(vector(1536, 260)))
        end)

        it('should return (0, 1) in region (0, 1) even when close to left edge (limit)', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          -- X  |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0, 1), state:get_map_region_coords(vector(0, 384)))
        end)

        it('should return (0, 1) in region (0, 1) right in the middle', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --  X |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          assert.are_equal(vector(0, 1), state:get_map_region_coords(vector(512, 384)))
        end)

        it('should return (0, 2) in region (0, 2) even when close to bottom and left edges (limit)', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          -- X  |
          assert.are_equal(vector(0, 2), state:get_map_region_coords(vector(0, 767)))
        end)

        it('should return (1, 2) in region (1, 2) even when close to bottom and right edges (limit)', function ()
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |
          -- ---+---
          --    |
          --    |
          --    |  X
          assert.are_equal(vector(1, 2), state:get_map_region_coords(vector(2047, 767)))
        end)

      end)

      describe('reload_map_region', function ()

        setup(function ()
          stub(_G, "reload")
          stub(stage_state, "reload_vertical_half_of_map_region")
          stub(stage_state, "reload_horizontal_half_of_map_region")
          stub(stage_state, "reload_quarter_of_map_region")
        end)

        teardown(function ()
          _G.reload:revert()
          stage_state.reload_vertical_half_of_map_region:revert()
          stage_state.reload_horizontal_half_of_map_region:revert()
          stage_state.reload_quarter_of_map_region:revert()
        end)

        -- on_enter calls check_reload_map_region, so reset count for all reload utility methods
        before_each(function ()
          _G.reload:clear()
          stage_state.reload_vertical_half_of_map_region:clear()
          stage_state.reload_horizontal_half_of_map_region:clear()
          stage_state.reload_quarter_of_map_region:clear()

          state.curr_stage_id = 2
        end)

        it('should call reload for map 01 for region coords (0, 1)', function ()
          state:reload_map_region(vector(0, 1))

          assert.spy(reload).was_called(1)
          assert.spy(reload).was_called_with(0x2000, 0x2000, 0x1000, "data_stage2_01.p8")
        end)

        it('should call reload_vertical_half_of_map_region for map 10 and 11 for region coords (1, 0.5)', function ()
          state:reload_map_region(vector(1, 0.5))

          assert.spy(stage_state.reload_vertical_half_of_map_region).was_called(2)
          assert.spy(stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.up, "data_stage2_10.p8")
          assert.spy(stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.down, "data_stage2_11.p8")
        end)

        it('should call reload_horizontal_half_of_map_region for map 00 and 10 for region coords (0.5, 0)', function ()
          state:reload_map_region(vector(0.5, 0))

          assert.spy(stage_state.reload_horizontal_half_of_map_region).was_called(2)
          assert.spy(stage_state.reload_horizontal_half_of_map_region).was_called_with(match.ref(state), horizontal_dirs.left, "data_stage2_00.p8")
          assert.spy(stage_state.reload_horizontal_half_of_map_region).was_called_with(match.ref(state), horizontal_dirs.right, "data_stage2_10.p8")
        end)

        it('should call reload_horizontal_half_of_map_region for map 00 and 10 for region coords (0.5, 0)', function ()
          state:reload_map_region(vector(0.5, 0.5))

          assert.spy(stage_state.reload_quarter_of_map_region).was_called(4)
          assert.spy(stage_state.reload_quarter_of_map_region).was_called_with(match.ref(state), horizontal_dirs.left, vertical_dirs.up, "data_stage2_00.p8")
          assert.spy(stage_state.reload_quarter_of_map_region).was_called_with(match.ref(state), horizontal_dirs.right, vertical_dirs.up, "data_stage2_10.p8")
          assert.spy(stage_state.reload_quarter_of_map_region).was_called_with(match.ref(state), horizontal_dirs.left, vertical_dirs.down, "data_stage2_01.p8")
          assert.spy(stage_state.reload_quarter_of_map_region).was_called_with(match.ref(state), horizontal_dirs.right, vertical_dirs.down, "data_stage2_11.p8")
        end)

        it('should set loaded_map_region_coords to the passed region', function ()
          state.loaded_map_region_coords = vector(0, 0)

          state:reload_map_region(vector(1, 0.5))

          assert.are_equal(vector(1, 0.5), state.loaded_map_region_coords)
        end)

      end)

      describe('check_reload_map_region', function ()

        setup(function ()
          stub(stage_state, "get_map_region_coords", function (self, position)
            -- see before_each below
            if position == vector(200, 64) then
              return vector(1, 0.5)
            end
            return vector(0, 0)
          end)
          stub(stage_state, "reload_map_region")
        end)

        teardown(function ()
          stage_state.get_map_region_coords:revert()
          stage_state.reload_map_region:revert()
        end)

        before_each(function ()
          -- dummy PC so it doesn't error, the stub above really decides of the result
          state.player_char = {position = vector(0, 0)}
          -- at least set some camera position used in get_map_region_coords stub
          --  so we can verify we are passing it correctly
          state.camera.position = vector(200, 64)
        end)

        after_each(function ()
          stage_state.get_map_region_coords:clear()
          stage_state.reload_map_region:clear()
        end)

        it('should call reload_map_region with (1, 0.5)', function ()
          state.loaded_map_region_coords = vector(0, 0)

          state:check_reload_map_region()

          assert.spy(stage_state.reload_map_region).was_called(1)
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(1, 0.5))
        end)

        it('should not call reload_map_region with (1, 0.5) if no change occurs', function ()
          state.loaded_map_region_coords = vector(1, 0.5)
          state:check_reload_map_region()

          assert.spy(stage_state.reload_map_region).was_not_called()
        end)

      end)

      describe('get_spawn_object_callback', function ()

        it('should return stage_state.spawn_emerald_at for visual.emerald_repr_sprite_id', function ()
          assert.are_equal(stage_state.spawn_emerald_at, state:get_spawn_object_callback(visual.emerald_repr_sprite_id))
        end)

        it('should return stage_state.spawn_palm_tree_leaves_at for visual.palm_tree_leaves_core_id', function ()
          assert.are_equal(stage_state.spawn_palm_tree_leaves_at, state:get_spawn_object_callback(visual.palm_tree_leaves_core_id))
        end)

        it('should return stage_state.spawn_goal_plate_at for visual.goal_plate_base_id', function ()
          assert.are_equal(stage_state.spawn_goal_plate_at, state:get_spawn_object_callback(visual.goal_plate_base_id))
        end)

      end)

      describe('spawn_objects_in_all_map_regions', function ()

        setup(function ()
          stub(stage_state, "reload_map_region")
          stub(stage_state, "scan_current_region_to_spawn_objects")
        end)

        teardown(function ()
          stage_state.reload_map_region:revert()
          stage_state.scan_current_region_to_spawn_objects:revert()
        end)

        after_each(function ()
          stage_state.reload_map_region:clear()
          stage_state.scan_current_region_to_spawn_objects:clear()
        end)

        it('should call reload every map on the 2x3 grid = 6 calls, calling scan_current_region_to_spawn_objects as many times', function ()
          state.curr_stage_data = {
            tile_width = 250,     -- not exactly 256 to test ceiling to 2 regions per row
            tile_height = 32 * 3  -- 3 regions per column
          }
          state.loaded_map_region_coords = vector(1, 0.5)

          state:spawn_objects_in_all_map_regions()

          assert.spy(stage_state.reload_map_region).was_called(6)
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(0, 0))
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(1, 0))
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(0, 1))
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(1, 1))
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(0, 2))
          assert.spy(stage_state.reload_map_region).was_called_with(match.ref(state), vector(1, 2))

          assert.spy(stage_state.scan_current_region_to_spawn_objects).was_called(6)
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
            -- we don't really mind spying on spawn_objects_in_all_map_regions
            --  but we do not want to spend several seconds finding all of them
            --  in before_each every time due to on_enter just for tests,
            --  so we stub this
              stub(stage_state, "spawn_objects_in_all_map_regions")
          end)

          teardown(function ()
            stage_state.spawn_objects_in_all_map_regions:revert()
          end)

          after_each(function ()
            stage_state.spawn_objects_in_all_map_regions:clear()
          end)

          before_each(function ()
            flow:change_state(state)
            -- entering stage currently starts coroutine show_stage_title_async
            -- which will cause side effects when updating coroutines to test other
            -- async functions, so clear that now
            state.app:stop_all_coroutines()
          end)

          describe('spawn_player_char', function ()

            setup(function ()
              spy.on(player_char, "spawn_at")
            end)

            teardown(function ()
              player_char.spawn_at:revert()
            end)

            before_each(function ()
              -- clear count before test as entering stage will auto-spawn character once
              player_char.spawn_at:clear()
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

          describe('update_fx', function ()

            setup(function ()
              stub(emerald_fx, "update", function (self)
                -- just a trick to force fx deactivation without going through
                --  the full animated sprite logic (nor stubbing is_active itself,
                --  as we really want to deactivate on update only to make sure it was called)
                if self.position.x == 999 then
                  self.anim_spr.playing = false
                end
              end)
            end)

            teardown(function ()
              emerald_fx.update:revert()
            end)

            after_each(function ()
              emerald_fx.update:clear()
            end)

            it('should call update on each emerald fx', function ()
              state.emerald_pick_fxs = {
                emerald_fx(1, vector(0, 0)),
                emerald_fx(2, vector(12, 4))
              }

              state:update_fx()

              assert.spy(emerald_fx.update).was_called(2)
              assert.spy(emerald_fx.update).was_called_with(match.ref(state.emerald_pick_fxs[1]))
              assert.spy(emerald_fx.update).was_called_with(match.ref(state.emerald_pick_fxs[2]))
            end)

            it('should call delete on each emerald fx inactive *after* update', function ()
              -- add fx to delete on first and last position, to make sure
              --  we don't make the mistake or deleting fx during iteration, which tends
              --  to make us miss the last elements
              state.emerald_pick_fxs = {
                emerald_fx(1, vector(999, 1)),
                emerald_fx(2, vector(2, 2)),
                emerald_fx(3, vector(999, 3))
              }

              state:update_fx()

              assert.are_same({
                emerald_fx(2, vector(2, 2))
              }, state.emerald_pick_fxs)
            end)

          end)

          describe('render_fx', function ()

            setup(function ()
              stub(stage_state, "set_camera_with_origin")
              stub(emerald_fx, "render")
            end)

            teardown(function ()
              stage_state.set_camera_with_origin:revert()
              emerald_fx.render:revert()
            end)

            after_each(function ()
              stage_state.set_camera_with_origin:clear()
              emerald_fx.render:clear()
            end)

            it('render_player_char should call set_camera_with_origin', function ()
              state:render_fx()

              assert.spy(stage_state.set_camera_with_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
            end)

            it('should call render on each emerald fx', function ()
              state.emerald_pick_fxs = {
                emerald_fx(1, vector(0, 0)),
                emerald_fx(2, vector(12, 4))
              }

              state:render_fx()

              assert.spy(emerald_fx.render).was_called(2)
              assert.spy(emerald_fx.render).was_called_with(match.ref(state.emerald_pick_fxs[1]))
              assert.spy(emerald_fx.render).was_called_with(match.ref(state.emerald_pick_fxs[2]))
            end)

          end)

          describe('update', function ()

            setup(function ()
              stub(stage_state, "update_fx")
              stub(player_char, "update")
              stub(stage_state, "check_reached_goal")
              stub(goal_plate, "update")
              stub(camera_class, "update")
            end)

            teardown(function ()
              stage_state.update_fx:revert()
              player_char.update:revert()
              stage_state.check_reached_goal:revert()
              goal_plate.update:revert()
              camera_class.update:revert()
            end)

            before_each(function ()
              -- check_reload_map_region must not be stubbed in setup, which would happen
              --  before the before_each -> flow:change_state(state) of (stage state entered)
              --  context. Instead we stub and revert before and after each
              -- (alternatively we could spy.on if we don't mind extra work during tests)
              -- in general we should actually avoid relying on complex methods like change_state
              --  in before_each and just manually set the properties we really need on state
              stub(stage_state, "check_reload_map_region")
            end)

            after_each(function ()
              stage_state.update_fx:clear()
              player_char.update:clear()
              stage_state.check_reached_goal:clear()
              goal_plate.update:clear()
              camera_class.update:clear()

              stage_state.check_reload_map_region:revert()
            end)

            describe('(current substate is play)', function ()

              it('should call fx and character update, check_reached_goal, goal update, camera update, check_reload_map_region', function ()
                state.current_substate = stage_state.substates.play
                state.goal_plate = goal_plate(location(100, 0))

                state:update()

                assert.spy(stage_state.update_fx).was_called(1)
                assert.spy(stage_state.update_fx).was_called_with(match.ref(state))
                assert.spy(player_char.update).was_called(1)
                assert.spy(player_char.update).was_called_with(match.ref(state.player_char))

                assert.spy(stage_state.check_reached_goal).was_called(1)
                assert.spy(stage_state.check_reached_goal).was_called_with(match.ref(state))
                assert.spy(goal_plate.update).was_called(1)
                assert.spy(goal_plate.update).was_called_with(match.ref(state.goal_plate))
                assert.spy(camera_class.update).was_called(1)
                assert.spy(camera_class.update).was_called_with(match.ref(state.camera))
                assert.spy(stage_state.check_reload_map_region).was_called(1)
                assert.spy(stage_state.check_reload_map_region).was_called_with(match.ref(state))
              end)

              it('should not try to update goal if no goal plate found (safety check for itests)', function ()
                state.current_substate = stage_state.substates.play
                state.goal_plate = nil

                state:update()

                assert.spy(goal_plate.update).was_not_called()
              end)

            end)

            describe('(current substate is result)', function ()

              it('should call fx and character update, not other element updates', function ()
                state.current_substate = stage_state.substates.result

                state:update()

                assert.spy(stage_state.update_fx).was_called(1)
                assert.spy(stage_state.update_fx).was_called_with(match.ref(state))
                assert.spy(player_char.update).was_called(1)
                assert.spy(player_char.update).was_called_with(match.ref(state.player_char))

                assert.spy(stage_state.check_reached_goal).was_not_called()
                assert.spy(camera_class.update).was_not_called()
                assert.spy(stage_state.check_reload_map_region).was_not_called()
              end)

            end)

          end)  -- update

          describe('render', function ()

            setup(function ()
              stub(stage_state, "render_background")
              stub(stage_state, "render_stage_elements")
              stub(stage_state, "render_fx")
              stub(stage_state, "render_hud")
              stub(stage_state, "render_overlay")
              stub(stage_state, "render_emerald_cross")
            end)

            teardown(function ()
              stage_state.render_background:revert()
              stage_state.render_stage_elements:revert()
              stage_state.render_fx:revert()
              stage_state.render_hud:revert()
              stage_state.render_overlay:revert()
              stage_state.render_emerald_cross:revert()
            end)

            after_each(function ()
              stage_state.render_background:clear()
              stage_state.render_stage_elements:clear()
              stage_state.render_fx:clear()
              stage_state.render_hud:clear()
              stage_state.render_overlay:clear()
              stage_state.render_emerald_cross:clear()
            end)

            it('should call render_background, render_stage_elements, render_fx, render_hud, render_overlay', function ()
              state:render()
              assert.spy(stage_state.render_background).was_called(1)
              assert.spy(stage_state.render_background).was_called_with(match.ref(state))
              assert.spy(stage_state.render_stage_elements).was_called(1)
              assert.spy(stage_state.render_stage_elements).was_called_with(match.ref(state))
              assert.spy(stage_state.render_fx).was_called(1)
              assert.spy(stage_state.render_fx).was_called_with(match.ref(state))
              assert.spy(stage_state.render_hud).was_called(1)
              assert.spy(stage_state.render_hud).was_called_with(match.ref(state))
              assert.spy(stage_state.render_overlay).was_called(1)
              assert.spy(stage_state.render_overlay).was_called_with(match.ref(state))
            end)

            it('(play) should not call render_emerald_cross', function ()
              state.current_substate = stage_state.substates.play

              state:render()

              assert.spy(stage_state.render_emerald_cross).was_not_called()
            end)

            it('(result) should call render_emerald_cross', function ()
              state.current_substate = stage_state.substates.result

              state:render()

              assert.spy(stage_state.render_emerald_cross).was_called(1)
              assert.spy(stage_state.render_emerald_cross).was_called_with(match.ref(state))
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

            -- we need to stub start_coroutine on the child class
            --  not gameapp or calls won't be monitored

            setup(function ()
              stub(picosonic_app, "start_coroutine")
            end)

            teardown(function ()
              picosonic_app.start_coroutine:revert()
            end)

            -- clear in before_each as stage_state on_enter
            --  will start some coroutune already
            before_each(function ()
              picosonic_app.start_coroutine:clear()
            end)

            before_each(function ()
              state.emeralds = {
                emerald(1, location(0, 0)),
                emerald(2, location(1, 0)),
                emerald(3, location(0, 1)),
              }
            end)

            it('should add an emerald number to the picked set', function ()
              state.picked_emerald_numbers_set = {
                [4] = true
              }
              state.emeralds = {
                emerald(1, location(0, 0)),
                emerald(2, location(1, 0)),
                emerald(3, location(0, 1)),
              }
              state:character_pick_emerald(state.emeralds[2])
              assert.are_same({[2] = true, [4] = true}, state.picked_emerald_numbers_set)
            end)

            it('should create a pick FX and play it', function ()
              state.emerald_pick_fxs = {
                emerald_fx(1, vector(0, 0))
              }

              state:character_pick_emerald(state.emeralds[2])

              -- emerald 2 was at location (1, 0),
              --  so its center was at (12, 4)
              assert.are_same({
                  emerald_fx(1, vector(0, 0)),
                  emerald_fx(2, vector(12, 4))
                },
                state.emerald_pick_fxs)
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

            it('should play character_pick_emerald sfx', function ()
              state:character_pick_emerald(state.emeralds[2])
              assert.spy(picosonic_app.start_coroutine).was_called(1)
              assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_state.play_pick_emerald_jingle_async, match.ref(state))
            end)

          end)

          describe('check_loop_external_triggers', function ()

            before_each(function ()
              -- customize loop areas locally. We are redefining a table so that won't affect
              --  the original data table in stage_data.lua. To simplify we don't redefine everything,
              --  but if we need to for the tests we'll just add the missing members
              state.curr_stage_data = {
                loop_exit_areas = {location_rect(-1, 0, 0, 2)},
                loop_entrance_areas = {location_rect(1, 0, 3, 4)}
              }
            end)

            it('should return nil when not entering external entrance trigger at all', function ()
              assert.is_nil(state:check_loop_external_triggers(vector(-20, 0), 2))
            end)

            it('should return 1 when entering external entrance trigger and not yet on layer 1', function ()
              assert.are_equal(1, state:check_loop_external_triggers(vector(-11, 0), 2))
            end)

            it('should return 1 when entering external entrance trigger but already on layer 1', function ()
              assert.is_nil(state:check_loop_external_triggers(vector(-11, 0), 1))
            end)

            it('should return 2 when entering external entrance trigger and not yet on layer 2', function ()
              -- to get bottom/left of a tile you need to add 1 to i/j
              assert.are_equal(2, state:check_loop_external_triggers(vector((3+1)*8+4, (4+1)*8), 1))
            end)

            it('should return nil when entering external entrance trigger but already on layer 2', function ()
              assert.is_nil(state:check_loop_external_triggers(vector((3+1)*8+4, (4+1)*8), 2))
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

            describe('(no goal)', function ()

              -- should be each
              before_each(function ()
                state.player_char.position = vector(1000, 0)
                state:check_reached_goal()
              end)

              it('should not set has_player_char_reached_goal to true', function ()
                assert.is_false(state.has_player_char_reached_goal)
              end)

              it('should not start on_reached_goal_async', function ()
                assert.spy(picosonic_app.start_coroutine).was_not_called()
              end)

            end)

            describe('(before the goal)', function ()

              -- should be each
              before_each(function ()
                state.goal_plate = goal_plate(location(100, 0))
                state.player_char.position = vector(804 - 1, 0)
                state:check_reached_goal()
              end)

              it('should not set has_player_char_reached_goal to true', function ()
                assert.is_false(state.has_player_char_reached_goal)
              end)

              it('should not start on_reached_goal_async', function ()
                assert.spy(picosonic_app.start_coroutine).was_not_called()
              end)

            end)

            describe('(just on the goal)', function ()

              before_each(function ()
                state.goal_plate = goal_plate(location(100, 0))
                state.player_char.position = vector(804, 0)
                state:check_reached_goal()
              end)

              it('should set has_player_char_reached_goal to true', function ()
                assert.is_true(state.has_player_char_reached_goal)
              end)

              it('should start on_reached_goal_async', function ()
                assert.spy(picosonic_app.start_coroutine).was_called(1)
                assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_state.on_reached_goal_async, match.ref(state))
              end)

            end)

            describe('(just on the goal, but already reached once)', function ()

              before_each(function ()
                state.goal_plate = goal_plate(location(100, 0))
                state.player_char.position = vector(804, 0)
                state.has_player_char_reached_goal = true
                state:check_reached_goal()
              end)

              it('should keep has_player_char_reached_goal as true', function ()
                assert.is_true(state.has_player_char_reached_goal)
              end)

              it('should not call on_reached_goal_async again', function ()
                assert.spy(picosonic_app.start_coroutine).was_not_called()
              end)

            end)

          end)

          describe('#solo on_reached_goal_async', function ()

            -- removed actual tests, too hard to maintain
            -- instead, just run it and see if it crashes

            local corunner

            before_each(function ()
              state.goal_plate = goal_plate(location(100, 0))
              state.spawned_emerald_locations = {1, 2, 3, 4, 5, 6, 7, 8}

              corunner = coroutine_runner()
              corunner:start_coroutine(stage_state.on_reached_goal_async, state)
            end)

            it('should not crash with a few emeralds', function ()
              state.emeralds = {5, 6, 7, 8}

              -- a time long enough to cover other async methods like assess_result_async
              for i = 1, 1000 do
                corunner:update_coroutines()
              end
            end)

            it('should not crash with all emeralds', function ()
              state.emeralds = {}

              -- a time long enough to cover other async methods like assess_result_async
              for i = 1, 1000 do
                corunner:update_coroutines()
              end
            end)

          end)

          describe('feedback_reached_goal', function ()

            setup(function ()
              stub(_G, "sfx")
              stub(animated_sprite, "play")
            end)

            teardown(function ()
              sfx:revert()
              animated_sprite.play:revert()
            end)

            after_each(function ()
              sfx:clear()
            end)

            before_each(function ()
              state.goal_plate = goal_plate(location(100, 0))

              -- was called before, including just above as goal_plat:init
              --  has a default animation, so clear at the end of before_each
              animated_sprite.play:clear()
            end)

            it('should play goal_reached sfx', function ()
              state:feedback_reached_goal()
              assert.spy(sfx).was_called(1)
              assert.spy(sfx).was_called_with(audio.sfx_ids.goal_reached)
            end)

            it('should play goal_plate "rotating" anim', function ()
              state:feedback_reached_goal()
              assert.spy(animated_sprite.play).was_called(1)
              assert.spy(animated_sprite.play).was_called_with(match.ref(state.goal_plate.anim_spr), "rotating")
            end)

          end)

          describe('back_to_titlemenu', function ()

            setup(function ()
              stub(_G, "load")
            end)

            teardown(function ()
              load:revert()
            end)

            it('should load cartridge: picosonic_titlemenu.p8', function ()
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

          describe('set_camera_with_origin', function ()

            it('should set the pico8 camera so that it is centered on the camera position, with origin (0, 0) by default', function ()
              state.camera.position = vector(24, 13)
              state:set_camera_with_origin()
              assert.are_same(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
            end)

            it('should set the pico8 camera so that it is centered on the camera position, with custom origin subtracted', function ()
              state.camera.position = vector(24, 13)
              state:set_camera_with_origin(vector(10, 20))
              assert.are_same(vector(24 - 128 / 2 - 10, 13 - 128 / 2 - 20), vector(pico8.camera_x, pico8.camera_y))
            end)

          end)

          describe('set_camera_with_region_origin', function ()

            setup(function ()
              stub(stage_state, "set_camera_with_origin")
            end)

            teardown(function ()
              stage_state.set_camera_with_origin:revert()
            end)

            after_each(function ()
              stage_state.set_camera_with_origin:clear()
            end)

            it('should call set_camera_with_origin with current region topleft xy', function ()
              state.loaded_map_region_coords = vector(2, 1)

              state:set_camera_with_region_origin()

              assert.spy(state.set_camera_with_origin).was_called(1)
              assert.spy(state.set_camera_with_origin).was_called_with(match.ref(state), vector(tile_size * map_region_tile_width * 2, tile_size * map_region_tile_height * 1))
            end)

          end)

          describe('render_stage_elements', function ()

            setup(function ()
              stub(stage_state, "render_environment_midground")
              stub(stage_state, "render_emeralds")
              stub(stage_state, "render_goal_plate")
              stub(stage_state, "render_player_char")
              stub(stage_state, "render_environment_foreground")
              stub(stage_state, "debug_render_trigger")
              stub(player_char, "debug_draw_rays")
            end)

            teardown(function ()
              stage_state.render_environment_midground:revert()
              stage_state.render_emeralds:revert()
              stage_state.render_goal_plate:revert()
              stage_state.render_player_char:revert()
              stage_state.render_environment_foreground:revert()
              stage_state.debug_render_trigger:revert()
              player_char.debug_draw_rays:revert()
            end)

            after_each(function ()
              stage_state.render_environment_midground:clear()
              stage_state.render_emeralds:clear()
              stage_state.render_goal_plate:clear()
              stage_state.render_player_char:clear()
              stage_state.render_environment_foreground:clear()
              stage_state.debug_render_trigger:clear()
              player_char.debug_draw_rays:clear()
            end)

            it('should call render methods on everything in the stage', function ()
              state:render_stage_elements()
              assert.spy(state.render_environment_midground).was_called(1)
              assert.spy(state.render_environment_midground).was_called_with(match.ref(state))
              assert.spy(state.render_emeralds).was_called(1)
              assert.spy(state.render_emeralds).was_called_with(match.ref(state))
              assert.spy(state.render_goal_plate).was_called(1)
              assert.spy(state.render_goal_plate).was_called_with(match.ref(state))
              assert.spy(state.render_player_char).was_called(1)
              assert.spy(state.render_player_char).was_called_with(match.ref(state))
              assert.spy(state.render_environment_foreground).was_called(1)
              assert.spy(state.render_environment_foreground).was_called_with(match.ref(state))
              -- #debug_trigger only
              assert.spy(state.debug_render_trigger).was_called(1)
              assert.spy(state.debug_render_trigger).was_called_with(match.ref(state))
              -- #debug_trigger only end
              -- #debug_character only
              assert.spy(player_char.debug_draw_rays).was_called(1)
              assert.spy(player_char.debug_draw_rays).was_called_with(match.ref(state.player_char))
              -- #debug_character only end
            end)

          end)

          describe('render_overlay', function ()

            setup(function ()
              stub(overlay, "draw_labels")
            end)

            teardown(function ()
              overlay.draw_labels:revert()
            end)

            after_each(function ()
              overlay.draw_labels:clear()
            end)

            it('should reset camera', function ()
              state:render_overlay()
              assert.are_same(vector.zero(), vector(pico8.camera_x, pico8.camera_y))
            end)

            it('should call title_overlay:draw_labels and result_overlay:draw_labels', function ()
              state:render_overlay()
              assert.spy(overlay.draw_labels).was_called(2)
              assert.spy(overlay.draw_labels).was_called_with(match.ref(state.title_overlay))
              assert.spy(overlay.draw_labels).was_called_with(match.ref(state.result_overlay))
            end)

          end)

          describe('render_background', function ()

            it('should reset camera position', function ()
              -- set a value so that 156 - 0.5 * self.camera.position.y is between -32 and 58,
              --  just so we try to draw both background sea at the top, and forest bottom
              state.camera.position = vector(24, 220)

              state:render_background()

              -- calls include rectfill and MANY line calls but we don't check background details, human tests are better for this
              -- otherwise we'd have something like:
              -- assert.spy(line).was_called(771)
            end)

          end)

          describe('render_player_char', function ()

            setup(function ()
              stub(stage_state, "set_camera_with_origin")
              stub(player_char, "render")
            end)

            teardown(function ()
              stage_state.set_camera_with_origin:revert()
              player_char.render:revert()
            end)

            after_each(function ()
              stage_state.set_camera_with_origin:clear()
              player_char.render:clear()
            end)

            it('should call set_camera_with_origin and player_char:render', function ()
              state:render_player_char()

              assert.spy(stage_state.set_camera_with_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
              assert.spy(player_char.render).was_called(1)
              assert.spy(player_char.render).was_called_with(match.ref(state.player_char))
            end)

          end)

          describe('render_emeralds', function ()

            setup(function ()
              stub(stage_state, "set_camera_with_origin")
              stub(emerald, "render")
            end)

            teardown(function ()
              stage_state.set_camera_with_origin:revert()
              emerald.render:revert()
            end)

            after_each(function ()
              stage_state.set_camera_with_origin:clear()
              emerald.render:clear()
            end)

            it('should call set_camera_with_origin and emerald:render', function ()
              state.emeralds = {
                emerald(1, location(1, 1)),
                emerald(2, location(2, 2)),
              }

              state:render_emeralds()

              assert.spy(stage_state.set_camera_with_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
              assert.spy(emerald.render).was_called(2)
              assert.spy(emerald.render).was_called_with(match.ref(state.emeralds[1]))
              assert.spy(emerald.render).was_called_with(match.ref(state.emeralds[2]))
            end)

          end)

          describe('render_goal_plate', function ()

            setup(function ()
              stub(stage_state, "set_camera_with_origin")
              stub(goal_plate, "render")
            end)

            teardown(function ()
              stage_state.set_camera_with_origin:revert()
              goal_plate.render:revert()
            end)

            after_each(function ()
              stage_state.set_camera_with_origin:clear()
              goal_plate.render:clear()
            end)

            it('(no goal plate found) should do nothing', function ()
              state:render_goal_plate()

              assert.spy(stage_state.set_camera_with_origin).was_not_called()
              assert.spy(goal_plate.render).was_not_called()
            end)

            it('(goal plate found) should call set_camera_with_origin and goal_plate:render', function ()
              state.goal_plate = goal_plate(location(2, 33))

              state:render_goal_plate()

              assert.spy(stage_state.set_camera_with_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
              assert.spy(goal_plate.render).was_called(1)
              assert.spy(goal_plate.render).was_called_with(match.ref(state.goal_plate))
            end)

          end)

          describe('render_hud', function ()

            setup(function ()
              stub(emerald, "draw")
              stub(player_char, "debug_print_info")
            end)

            teardown(function ()
              emerald.draw:revert()
              player_char.debug_print_info:revert()
            end)

            after_each(function ()
              emerald.draw:clear()
              player_char.debug_print_info:clear()
            end)

            it('(play) should call emerald.draw for each emerald, true color for picked ones and silhouette for unpicked ones', function ()
              state.current_substate = stage_state.substates.play

              state.spawned_emerald_locations = {
                -- dummy values just to have correct count (3, counting hole on 2)
                location(1, 1), location(2, 2), location(3, 3)
              }
              state.picked_emerald_numbers_set = {
                [1] = true,
                [3] = true
              }

              state:render_hud()

              assert.spy(emerald.draw).was_called(3)
              assert.spy(emerald.draw).was_called_with(1, vector(6, 6))
              -- silhouette only
              assert.spy(emerald.draw).was_called_with(-1, vector(16, 6))
              assert.spy(emerald.draw).was_called_with(3, vector(26, 6))
            end)

            it('(result) should not draw emeralds on the top-left hud', function ()
              state.current_substate = stage_state.substates.result

              state.spawned_emerald_locations = {
                -- dummy values just to have correct count (3, counting hole on 2)
                location(1, 1), location(2, 2), location(3, 3)
              }
              state.picked_emerald_numbers_set = {
                [1] = true,
                [3] = true
              }

              state:render_hud()

              assert.spy(emerald.draw).was_not_called()
            end)

            it('should debug render character info (#debug_character only)', function ()
              state:render_hud()

              assert.spy(player_char.debug_print_info).was_called(1)
              assert.spy(player_char.debug_print_info).was_called_with(match.ref(state.player_char))
            end)

          end)

          describe('(region at (2, 3))', function ()

            setup(function ()
              stub(stage_state, "get_region_topleft_location", function (self)
                return location(2, 3)
              end)
            end)

            teardown(function ()
              stage_state.get_region_topleft_location:revert()
            end)

            describe('global_to_region_location', function ()
              it('global loc (2, 4) - (2, 3) => (0, 1)', function ()
                assert.are_equal(location(0, 1), state:global_to_region_location(location(2, 4)))
              end)
            end)

            describe('region_to_global_location', function ()
              it('region loc (0, 1) + (2, 3) => (2, 4)', function ()
                assert.are_equal(location(2, 4), state:region_to_global_location(location(0, 1)))
              end)
            end)

          end)

          describe('get_region_topleft_location', function ()

            it('region (0, 0) => (0, 0)', function ()
              state.loaded_map_region_coords = vector(0, 0)
              assert.are_same(location(0, 0), state:get_region_topleft_location())
            end)

            it('region (0.5, 1) => (64, 32)', function ()
              state.loaded_map_region_coords = vector(0.5, 1)
              assert.are_same(location(64, 32), state:get_region_topleft_location())
            end)

          end)

          describe('(with tile_test_data)', function ()

            setup(function ()
              tile_test_data.setup()

              stub(stage_state, "set_camera_with_origin")
              stub(stage_state, "set_camera_with_region_origin")
              stub(sprite_data, "render")
              stub(_G, "spr")
              stub(_G, "map")
            end)

            teardown(function ()
              tile_test_data.teardown()

              stage_state.set_camera_with_origin:revert()
              stage_state.set_camera_with_region_origin:revert()
              sprite_data.render:revert()
              spr:revert()
              map:revert()
            end)

            before_each(function ()
              -- 2 midground tiles on screen, 1 outside when camera is at (0, 0)
              mock_mset(0, 0, tile_repr.spring_left_id)
              mock_mset(3, 0, tile_repr.spring_left_id)
              mock_mset(9, 0, tile_repr.spring_left_id)
              -- 1 undefined tile onscreen (it's foreground hiding leaf in PICO-8,
              --  but what matters here is that midground flag is not set)
              mock_mset(5, 0, 46)
              -- foreground tile to test foreground layer
              mock_mset(0, 1, tile_repr.grass_top_decoration1)

              state.curr_stage_data = {
                loop_exit_areas = {location_rect(-1, 0, 0, 2)},
                loop_entrance_areas = {location_rect(1, 0, 3, 4)},
                goal_x = 3000
              }

              -- palm tree example to demonstrate extra foreground
              state.palm_tree_leaves_core_global_locations = {
                location(10, 2)
              }
            end)

            after_each(function ()
              pico8:clear_map()

              stage_state.set_camera_with_origin:clear()
              stage_state.set_camera_with_region_origin:clear()
              sprite_data.render:clear()
              spr:clear()
              map:clear()
            end)

            it('render_environment_midground should call map for all midground sprites', function ()
              -- note that we reverted to using map for performance, so this test doesn't need to be
              --  in the tile test data setup context anymore
              state.camera.position = vector(0, 0)
              state.loaded_map_region_coords = vector(0, 0)

              state:render_environment_midground()

              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))

              assert.spy(map).was_called(1)
              assert.spy(map).was_called_with(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.midground)
            end)

            it('render_environment_foreground should call spr on tiles present on screen', function ()
              -- this test was copy-pasted from render_environment_midground
              state.camera.position = vector(0, 0)
              state.loaded_map_region_coords = vector(2, 1)

              state:render_environment_foreground()

              -- we can't check call order, but set camera methods should be called consistently with map!
              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))

              assert.spy(map).was_called(2)

              assert.spy(map).was_called_with(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.foreground)

              assert.spy(stage_state.set_camera_with_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))

              local area = state.curr_stage_data.loop_entrance_areas[1]
              -- (2, 1) comes from state.loaded_map_region_coords
              assert.spy(map).was_called_with(area.left - 2 * 128, area.top - 1 * 32,
                tile_size * area.left, tile_size * area.top,
                area.right - area.left + 1, area.bottom - area.top + 1,
                sprite_masks.midground)

              assert.spy(sprite_data.render).was_called(3)
              -- top
              assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.palm_tree_leaves_top), vector(8 * 10, 8 * 2))
              -- right
              assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.palm_tree_leaves_right), vector(8 * 11, 8 * 2))
              -- left (right flipped x)
              assert.spy(sprite_data.render).was_called_with(match.ref(visual.sprite_data_t.palm_tree_leaves_right), vector(8 * 10, 8 * 2), true)
            end)

          end)  -- (with tile_test_data)

          describe('#solo extra render methods (no-crash only)', function ()

            it('render_emerald_cross should not crash', function ()
              state:render_emerald_cross()
            end)

          end)

          describe('state audio methods', function ()

            setup(function ()
              stub(_G, "reload")
            end)

            teardown(function ()
              reload:revert()
            end)

            -- reload is called during on_enter for region loading, so clear call count now
            before_each(function ()
              reload:clear()
            end)

            after_each(function ()
              pico8.current_music = nil
            end)

            it('reload_bgm should start level bgm', function ()
              state:reload_bgm()

              assert.spy(reload).was_called(2)
              assert.spy(reload).was_called_with(0x3100, 0x3100, 0xa0, "data_bgm1.p8")
              assert.spy(reload).was_called_with(0x3200, 0x3200, 0xd48, "data_bgm1.p8")
            end)

            it('play_bgm should start level bgm', function ()
              state:play_bgm()

              assert.are_same({music=state.curr_stage_data.bgm_id, fadems=0, channel_mask=(1 << 0) + (1 << 1) + (1 << 2)}, pico8.current_music)
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
                -- spawn_objects_in_all_map_regions has been stubbed in this context,
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
                assert.is_false(state.has_player_char_reached_goal)
              end)

            end)

          end)  -- on exit stage state to enter titlemenu state

          -- unlike above, we test on_exit method itself here
          describe('on_exit', function ()

            setup(function ()
              stub(overlay, "clear_labels")
              stub(picosonic_app, "stop_all_coroutines")
              stub(stage_state, "stop_bgm")
              -- we don't really mind spying on spawn_objects_in_all_map_regions
              --  but we do not want to spend 0.5s finding all of them
              --  in before_each every time due to on_enter,
              --  so we stub this
              stub(stage_state, "spawn_objects_in_all_map_regions")
            end)

            teardown(function ()
              overlay.clear_labels:revert()
              picosonic_app.stop_all_coroutines:revert()
              stage_state.stop_bgm:revert()
              stage_state.spawn_objects_in_all_map_regions:revert()
            end)

            after_each(function ()
              overlay.clear_labels:clear()
              stage_state.stop_bgm:clear()
              stage_state.spawn_objects_in_all_map_regions:clear()
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

        end)  -- (stage state entered)

      end)  -- (stage states added)

    end)  -- (with instance)

  end)  -- (stage state)

end)
