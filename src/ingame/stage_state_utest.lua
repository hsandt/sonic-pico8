require("test/bustedhelper")
local stage_state = require("ingame/stage_state")

local flow = require("engine/application/flow")
local gamestate = require("engine/application/gamestate")
local location_rect = require("engine/core/location_rect")
local overlay = require("engine/ui/overlay")
local label = require("engine/ui/label")

local picosonic_app = require("application/picosonic_app_ingame")
local camera_data = require("data/camera_data")
local stage_data = require("data/stage_data")
local emerald = require("ingame/emerald")
local player_char = require("ingame/playercharacter")
local titlemenu = require("menu/titlemenu")
local audio = require("resources/audio")
local visual = require("resources/visual")
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
            vector.zero(),
            overlay(0),
            nil
          },
          {
            state.type,
            state.curr_stage_id,
            state.current_substate,
            state.player_char,
            state.has_reached_goal,
            state.spawned_emerald_locations,
            state.emeralds,
            state.camera_pos,
            state.title_overlay,
            state.loaded_map_region_coords
          })
      end)

      describe('on_enter', function ()

        setup(function ()
          stub(stage_state, "spawn_player_char")
          stub(picosonic_app, "start_coroutine")
          stub(stage_state, "play_bgm")
          stub(stage_state, "randomize_background_data")
          stub(stage_state, "spawn_objects_in_all_map_regions")
          stub(stage_state, "check_reload_map_region")
        end)

        teardown(function ()
          stage_state.spawn_player_char:revert()
          picosonic_app.start_coroutine:revert()
          stage_state.play_bgm:revert()
          stage_state.randomize_background_data:revert()
          stage_state.spawn_objects_in_all_map_regions:revert()
          stage_state.check_reload_map_region:revert()
        end)

        after_each(function ()
          stage_state.spawn_player_char:clear()
          picosonic_app.start_coroutine:clear()
          stage_state.play_bgm:clear()
          stage_state.randomize_background_data:clear()
          stage_state.spawn_objects_in_all_map_regions:clear()
          stage_state.check_reload_map_region:clear()
        end)

        before_each(function ()
          state:on_enter()
        end)

        it('should call spawn_objects_in_all_map_regions', function ()
          assert.spy(state.spawn_objects_in_all_map_regions).was_called(1)
          assert.spy(state.spawn_objects_in_all_map_regions).was_called_with(match.ref(state))
        end)

        it('should initialize camera at future character spawn position', function ()
          local spawn_position = state.curr_stage_data.spawn_location:to_center_position()
          assert.are_same(spawn_position, state.camera_pos)
        end)

        it('should call check_reload_map_region', function ()
          assert.spy(state.check_reload_map_region).was_called(1)
          assert.spy(state.check_reload_map_region).was_called_with(match.ref(state))
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

      describe('spawn_new_emeralds', function ()

        -- setup is too early, stage state will start afterward in before_each,
        --  and its on_enter will call spawn_new_emeralds, making it hard
        --  to test in isolation. Hence before_each.
        before_each(function ()
          local emerald_repr_sprite_id = visual.sprite_data_t.emerald.id_loc:to_sprite_id()
          -- we're not using tile_test_data.setup here (since emeralds are checked
          --  directly by id, not using collision data) so don't use mock_mset
          mset(1, 1, emerald_repr_sprite_id)
          mset(2, 2, emerald_repr_sprite_id)
          mset(3, 3, emerald_repr_sprite_id)

          state.loaded_map_region_coords = vector(0, 1)  -- will add 32 to each j
        end)

        after_each(function ()
          pico8:clear_map()
        end)

        it('should store new emerald global location to remember not to spawn it again', function ()
          state:spawn_new_emeralds()

          assert.are_same({
            location(1, 1 + 32),
            location(2, 2 + 32),
            location(3, 3 + 32),
          }, state.spawned_emerald_locations)
        end)

        it('should spawn and store new emerald objects for each emerald tile', function ()
          state:spawn_new_emeralds()

          assert.are_same({
            emerald(1, location(1, 1 + 32)),
            emerald(2, location(2, 2 + 32)),
            emerald(3, location(3, 3 + 32)),
          }, state.emeralds)
        end)

        it('should ignore emeralds already spawned ((2, 2 + 32) here)', function ()
          state.loaded_map_region_coords = vector(0, 1)
          state.spawned_emerald_locations = {
            location(2, 2 + 32),
          }

          state:spawn_new_emeralds()

          -- we'll still add 1 and 3, so result will be the same as above, but in different order
          assert.are_same({
            location(2, 2 + 32),
            location(1, 1 + 32),
            location(3, 3 + 32),
          }, state.spawned_emerald_locations)

          -- note that in our example we didn't have emerald object 2
          -- so supposedly we spawned it but also picked it earlier
          -- this means the emerald at (1, 1 + 32) starts at number 2 already
          assert.are_same({
            emerald(2, location(1, 1 + 32)),
            emerald(3, location(3, 3 + 32)),
          }, state.emeralds)
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
          stub(stage_state, "get_map_region_coords", function (self)
            return vector(1, 0.5)
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

      describe('spawn_objects_in_all_map_regions', function ()

        setup(function ()
          stub(stage_state, "reload_map_region")
          stub(stage_state, "spawn_new_emeralds")
        end)

        teardown(function ()
          stage_state.reload_map_region:revert()
          stage_state.spawn_new_emeralds:revert()
        end)

        after_each(function ()
          stage_state.reload_map_region:clear()
          stage_state.spawn_new_emeralds:clear()
        end)

        it('should call reload every map on the 2x3 grid, spawning emeralds at the same time', function ()
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

          assert.spy(stage_state.spawn_new_emeralds).was_called(6)
          assert.spy(stage_state.spawn_new_emeralds).was_called_with(match.ref(state))
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

          describe('update_camera', function ()

            before_each(function ()
              -- required for stage edge clamping
              -- we only need to mock width and height,
              --  normally we'd get full stage data as in stage_data.lua
              state.curr_stage_data = {
                tile_width = 100,
                tile_height = 20
              }
            end)

            it('should move the camera X so player X is on left edge if he goes beyond left edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.position = vector(120 - camera_data.window_half_width - 1, 80)

              state:update_camera()

              assert.are_equal(120 - 1, state.camera_pos.x)
            end)

            it('should not move the camera on X if player X remains in window X (left edge)', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.position = vector(120 - camera_data.window_half_width, 80)

              state:update_camera()

              assert.are_equal(120, state.camera_pos.x)
            end)

            it('should not move the camera on X if player X remains in window X (right edge)', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.position = vector(120 + camera_data.window_half_width, 80)

              state:update_camera()

              assert.are_equal(120, state.camera_pos.x)
            end)

            it('should move the camera X so player X is on right edge if he goes beyond right edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.position = vector(120 + camera_data.window_half_width + 1, 80)

              state:update_camera()

              assert.are_equal(120 + 1, state.camera_pos.x)
            end)

            -- forward extension, positive X

            it('forward extension: should increase forward extension by catch up speed when character reaches forward_ext_min_speed_x', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(camera_data.forward_ext_min_speed_x, 0)

              state:update_camera()

              assert.are_equal(camera_data.forward_ext_catchup_speed_x, state.camera_forward_ext_offset)
              assert.are_equal(120 + camera_data.forward_ext_catchup_speed_x, state.camera_pos.x)
            end)

            it('forward extension: should increase forward extension by catch up speed until max when character stays above forward_ext_min_speed_x for long', function ()
              state.camera_forward_ext_offset = camera_data.forward_ext_distance - 0.1  -- just subtract something lower than camera_data.forward_ext_distance
              -- to reproduce the fast that the camera is more forward that it should be with window only,
              --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
              state.camera_pos = vector(120 + state.camera_forward_ext_offset, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(camera_data.forward_ext_min_speed_x, 0)

              state:update_camera()

              assert.are_equal(camera_data.forward_ext_distance, state.camera_forward_ext_offset)
              assert.are_equal(120 + camera_data.forward_ext_distance, state.camera_pos.x)
            end)

            it('forward extension: should decrease forward extension by catch up speed when character goes below forward_ext_min_speed_x again', function ()
              state.camera_forward_ext_offset = camera_data.forward_ext_distance
              state.camera_pos = vector(120 + state.camera_forward_ext_offset, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(camera_data.forward_ext_min_speed_x - 1, 0)

              state:update_camera()

              assert.are_equal(camera_data.forward_ext_distance - camera_data.forward_ext_catchup_speed_x, state.camera_forward_ext_offset)
              assert.are_equal(120 + camera_data.forward_ext_distance - camera_data.forward_ext_catchup_speed_x, state.camera_pos.x)
            end)

            it('forward extension: should decrease forward extension back to 0 when character goes below forward_ext_min_speed_x for long', function ()
              state.camera_forward_ext_offset = 0.1  -- just something lower than camera_data.forward_ext_distance
              state.camera_pos = vector(120 + state.camera_forward_ext_offset, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(camera_data.forward_ext_min_speed_x - 1, 0)

              state:update_camera()

              assert.are_equal(0, state.camera_forward_ext_offset)
              assert.are_equal(120, state.camera_pos.x)
            end)

            -- same, but forward is negative X

            it('forward extension: should increase forward extension toward NEGATIVE by catch up speed when character reaches -forward_ext_min_speed_x', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(-camera_data.forward_ext_min_speed_x, 0)

              state:update_camera()

              assert.are_equal(-camera_data.forward_ext_catchup_speed_x, state.camera_forward_ext_offset)
              assert.are_equal(120 - camera_data.forward_ext_catchup_speed_x, state.camera_pos.x)
            end)

            it('forward extension: should increase forward extension toward NEGATIVE by catch up speed until max when character stays above -forward_ext_min_speed_x for long', function ()
              state.camera_forward_ext_offset = -(camera_data.forward_ext_distance - 0.1)  -- just subtract something lower than camera_data.forward_ext_distance
              -- to reproduce the fast that the camera is more forward that it should be with window only,
              --  we must add the forward ext offset (else utest won't pass as camera will lag behind)
              state.camera_pos = vector(120 + state.camera_forward_ext_offset, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(-camera_data.forward_ext_min_speed_x, 0)

              state:update_camera()

              assert.are_equal(-camera_data.forward_ext_distance, state.camera_forward_ext_offset)
              assert.are_equal(120 - camera_data.forward_ext_distance, state.camera_pos.x)
            end)

            it('forward extension: should decrease forward extension (in abs) by catch up speed when character goes below forward_ext_min_speed_x (in abs) again', function ()
              state.camera_forward_ext_offset = -camera_data.forward_ext_distance
              state.camera_pos = vector(120 + state.camera_forward_ext_offset, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(-(camera_data.forward_ext_min_speed_x - 1), 0)

              state:update_camera()

              assert.are_equal(-(camera_data.forward_ext_distance - camera_data.forward_ext_catchup_speed_x), state.camera_forward_ext_offset)
              assert.are_equal(120 - (camera_data.forward_ext_distance - camera_data.forward_ext_catchup_speed_x), state.camera_pos.x)
            end)

            it('forward extension: should decrease forward extension (in abs) back to 0 when character goes below forward_ext_min_speed_x (in abs) for long', function ()
              state.camera_forward_ext_offset = -0.1  -- just something lower (in abs) than camera_data.forward_ext_distance
              state.camera_pos = vector(120 + state.camera_forward_ext_offset, 80)
              state.player_char.position = vector(120, 80)
              state.player_char.velocity = vector(-(camera_data.forward_ext_min_speed_x - 1), 0)

              state:update_camera()

              assert.are_equal(0, state.camera_forward_ext_offset)
              assert.are_equal(120, state.camera_pos.x)
            end)

            -- Y

            it('(grounded, low ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond top edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              -- alternative +/- ground speed to check abs logic
              state.player_char.ground_speed = -(camera_data.fast_catchup_min_ground_speed - 0.5)
              -- it's hard to find realistic values for such a motion, where you're move slowly on a slope but still
              --  fast vertically... but it should be possible on a very high slope. Here we imagine a wall where we move
              --  at ground speed 3.5, 100% vertically!
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.slow_catchup_speed_y + 0.5))

              state:update_camera()

              -- extra 0.5 was cut
              assert.are_equal(80 - camera_data.slow_catchup_speed_y, state.camera_pos.y)
            end)

            it('(grounded, high ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond top edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = camera_data.fast_catchup_min_ground_speed
              -- unrealistic, we have ground speed 4 but still move by more than 8, impossible even on vertical wall... but good for testing
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.fast_catchup_speed_y + 0.5))

              state:update_camera()

              -- extra 0.5 was cut
              assert.are_equal(80 - camera_data.fast_catchup_speed_y, state.camera_pos.y)
            end)

            it('(grounded, low ground speed) should move the camera Y to match player Y if he goes beyond top edge slower than low catchup speed', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = camera_data.fast_catchup_min_ground_speed - 0.5
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.slow_catchup_speed_y - 0.5))

              state:update_camera()

              assert.are_equal(80 - (camera_data.slow_catchup_speed_y - 0.5), state.camera_pos.y)
            end)

            it('(grounded, high ground speed) should move the camera Y to match player Y if he goes beyond top edge slower than fast catchup speed', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = -camera_data.fast_catchup_min_ground_speed
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y - (camera_data.fast_catchup_speed_y - 0.5))

              state:update_camera()

              assert.are_equal(80 - (camera_data.fast_catchup_speed_y - 0.5), state.camera_pos.y)
            end)

            it('(grounded) should not move the camera Y if player Y remains in window Y (top edge)', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = -(camera_data.fast_catchup_min_ground_speed - 0.5)
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y)

              state:update_camera()

              assert.are_equal(80, state.camera_pos.y)
            end)

            it('(grounded) should not move the camera Y if player Y remains in window Y (bottom edge)', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = camera_data.fast_catchup_min_ground_speed
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y)

              state:update_camera()

              assert.are_equal(80, state.camera_pos.y)
            end)

            it('(grounded, low ground speed) should move the camera Y to match player Y if he goes beyond bottom edge slower than low catchup speed', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = camera_data.fast_catchup_min_ground_speed - 0.5
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.slow_catchup_speed_y - 0.5))

              state:update_camera()

              assert.are_equal(80 + (camera_data.slow_catchup_speed_y - 0.5), state.camera_pos.y)
            end)

            it('(grounded, high ground speed) should move the camera Y to match player Y if he goes beyond bottom edge slower than low catchup speed', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = -camera_data.fast_catchup_min_ground_speed
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.fast_catchup_speed_y - 0.5))

              state:update_camera()

              assert.are_equal(80 + (camera_data.fast_catchup_speed_y - 0.5), state.camera_pos.y)
            end)

            it('(grounded, low ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond bottom edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = -(camera_data.fast_catchup_min_ground_speed - 0.5)
              -- it's hard to find realistic values for such a motion, where you're move slowly on a slope but still
              --  fast vertically... but it should be possible on a very high slope. Here we imagine a wall where we move
              --  at ground speed 3.5, 100% vertically!
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.slow_catchup_speed_y + 0.5))

              state:update_camera()

              -- extra 0.5 was cut
              assert.are_equal(80 + camera_data.slow_catchup_speed_y, state.camera_pos.y)
            end)

            it('(grounded, high ground speed) should move the camera Y toward player position (so it matches reference Y) using slow catchup speed if he goes beyond bottom edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.grounded
              state.player_char.ground_speed = camera_data.fast_catchup_min_ground_speed
              -- unrealistic, we have ground speed 4 but still move by more than 8, impossible even on vertical wall... but good for testing
              state.player_char.position = vector(120, 80 + camera_data.window_center_offset_y + (camera_data.fast_catchup_speed_y + 0.5))

              state:update_camera()

              -- extra 0.5 was cut
              assert.are_equal(80 + camera_data.fast_catchup_speed_y, state.camera_pos.y)
            end)

            it('(airborne) should move the camera Y toward player Y with fast catchup speed (so that it gets closer to top edge) if player Y goes beyond top edge faster than fast_catchup_speed_y', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.air_spin
              state.player_char.position = vector(120 , 80 + camera_data.window_center_offset_y - camera_data.window_half_height - (camera_data.fast_catchup_speed_y + 5))

              state:update_camera()

              -- extra 5 was cut
              assert.are_equal(80 - camera_data.fast_catchup_speed_y, state.camera_pos.y)
            end)

            it('(airborne) should move the camera Y so player Y is on top edge if he goes beyond top edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.air_spin
              state.player_char.position = vector(120 , 80 + camera_data.window_center_offset_y - camera_data.window_half_height - 1)

              state:update_camera()

              assert.are_equal(80 - 1, state.camera_pos.y)
            end)

            it('(airborne) should not move the camera on Y if player Y remains in window Y (top edge)', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.air_spin
              state.player_char.position = vector(120 , 80 + camera_data.window_center_offset_y - camera_data.window_half_height)

              state:update_camera()

              assert.are_equal(80, state.camera_pos.y)
            end)

            it('(airborne) should not move the camera on X if player X remains in window X (bottom edge)', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.air_spin
              state.player_char.position = vector(120 , 80 + camera_data.window_center_offset_y + camera_data.window_half_height)

              state:update_camera()

              assert.are_equal(80, state.camera_pos.y)
            end)

            it('(airborne) should move the camera X so player X is on bottom edge if he goes beyond bottom edge', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.air_spin
              state.player_char.position = vector(120 , 80 + camera_data.window_center_offset_y + camera_data.window_half_height + 1)

              state:update_camera()

              assert.are_equal(80 + 1, state.camera_pos.y)
            end)

            it('(airborne) should move the camera Y toward player Y with fast catchup speed (so that it gets closer to bottom edge) if player Y goes beyond bottom edge faster than fast_catchup_speed_y', function ()
              state.camera_pos = vector(120, 80)
              state.player_char.motion_state = motion_states.air_spin
              state.player_char.position = vector(120 , 80 + camera_data.window_center_offset_y + camera_data.window_half_height + (camera_data.fast_catchup_speed_y + 5))

              state:update_camera()

              -- extra 5 was cut
              assert.are_equal(80 + camera_data.fast_catchup_speed_y, state.camera_pos.y)
            end)

            it('should move the camera to player position, clamped (top-left)', function ()
              -- start near/at the edge already, if you're too far the camera won't have
              --  time to reach the edge in one update due to smooth motion (in y)
              state.camera_pos = vector(64 + 3, 64 + 8)
              state.player_char.position = vector(12, 24)

              state:update_camera()

              assert.are_same(vector(64, 64), state.camera_pos)
            end)

            it('should move the camera to player position, clamped (bottom-right)', function ()
              -- start near/at the edge already, if you're too far the camera won't have
              --  time to reach the edge in one update due to smooth motion (in y)
              state.camera_pos = vector(800-64, 160-64)
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
              player_char.update:clear()
              stage_state.check_reached_goal:clear()
              stage_state.update_camera:clear()

              stage_state.check_reload_map_region:revert()
            end)

            describe('(current substate is play)', function ()

              it('should call player_char:update, check_reached_goal, update_camera, check_reload_map_region', function ()
                state.current_substate = stage_state.substates.play
                state:update()
                assert.spy(player_char.update).was_called(1)
                assert.spy(player_char.update).was_called_with(match.ref(state.player_char))
                assert.spy(stage_state.check_reached_goal).was_called(1)
                assert.spy(stage_state.check_reached_goal).was_called_with(match.ref(state))
                assert.spy(stage_state.update_camera).was_called(1)
                assert.spy(stage_state.update_camera).was_called_with(match.ref(state))
                assert.spy(stage_state.check_reload_map_region).was_called(1)
                assert.spy(stage_state.check_reload_map_region).was_called_with(match.ref(state))
              end)
            end)

            describe('(current substate is result)', function ()

              it('should not call player_char:update, check_reached_goal, update_camera, check_reload_map_region', function ()
                state.current_substate = stage_state.substates.result
                state:update()
                assert.spy(player_char.update).was_not_called()
                assert.spy(stage_state.check_reached_goal).was_not_called()
                assert.spy(stage_state.update_camera).was_not_called()
                assert.spy(stage_state.check_reload_map_region).was_not_called()
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

          describe('set_camera_with_origin', function ()

            it('should set the pico8 camera so that it is centered on the camera position, with origin (0, 0) by default', function ()
              state.camera_pos = vector(24, 13)
              state:set_camera_with_origin()
              assert.are_same(vector(24 - 128 / 2, 13 - 128 / 2), vector(pico8.camera_x, pico8.camera_y))
            end)

            it('should set the pico8 camera so that it is centered on the camera position, with custom origin subtracted', function ()
              state.camera_pos = vector(24, 13)
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

          describe('misc state render methods', function ()

            setup(function ()
              spy.on(stage_state, "set_camera_with_origin")
              spy.on(stage_state, "render_environment_midground")
              spy.on(stage_state, "render_environment_foreground")
              stub(stage_state, "debug_render_trigger")
              stub(player_char, "render")
              stub(emerald, "render")
              stub(overlay, "draw_labels")
            end)

            teardown(function ()
              stage_state.set_camera_with_origin:revert()
              stage_state.render_environment_midground:revert()
              stage_state.render_environment_foreground:revert()
              stage_state.debug_render_trigger:revert()
              player_char.render:revert()
              emerald.render:revert()
              overlay.draw_labels:revert()
            end)

            after_each(function ()
              stage_state.set_camera_with_origin:clear()
              stage_state.render_environment_midground:clear()
              stage_state.render_environment_foreground:clear()
              stage_state.debug_render_trigger:clear()
              player_char.render:clear()
              emerald.render:clear()
              overlay.draw_labels:clear()
            end)

            it('render_title_overlay should call title_overlay:draw_labels', function ()
              state:render_title_overlay()
              assert.are_same(vector.zero(), vector(pico8.camera_x, pico8.camera_y))
              assert.spy(overlay.draw_labels).was_called(1)
              assert.spy(overlay.draw_labels).was_called_with(match.ref(state.title_overlay))
            end)

            it('render_background should reset camera position', function ()
              state.camera_pos = vector(24, 13)
              state:render_background()
              assert.are_same(vector(0, 0), vector(pico8.camera_x, pico8.camera_y))

              -- more calls including rectfill and MANY line calls but we don't check background details, human tests are better for this
              -- assert.spy(line).was_called(771)
            end)

            it('render_stage_elements should call render_environment methods for environment and player_char:render', function ()
              state:render_stage_elements()
              assert.spy(state.render_environment_midground).was_called(1)
              assert.spy(state.render_environment_midground).was_called_with(match.ref(state))
              assert.spy(state.render_environment_foreground).was_called(1)
              assert.spy(state.render_environment_foreground).was_called_with(match.ref(state))
              -- #debug_trigger only
              assert.spy(state.debug_render_trigger).was_called(1)
              assert.spy(state.debug_render_trigger).was_called_with(match.ref(state))
              -- #debug_trigger only end
              assert.spy(player_char.render).was_called(1)
              assert.spy(player_char.render).was_called_with(match.ref(state.player_char))
            end)

            it('render_player_char should call set_camera_with_origin and player_char:render', function ()
              state:render_player_char()

              assert.spy(stage_state.set_camera_with_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
              assert.spy(player_char.render).was_called(1)
              assert.spy(player_char.render).was_called_with(match.ref(state.player_char))
            end)

            it('render_emeralds should call set_camera_with_origin and player_char:render', function ()
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
              stub(_G, "spr")
              stub(_G, "map")
            end)

            teardown(function ()
              tile_test_data.teardown()

              stage_state.set_camera_with_origin:revert()
              stage_state.set_camera_with_region_origin:revert()
              spr:revert()
              map:revert()
            end)

            before_each(function ()
              -- 2 midground tiles on screen, 1 outside when camera is at (0, 0)
              mock_mset(0, 0, spring_left_id)
              mock_mset(3, 0, spring_left_id)
              mock_mset(9, 0, spring_left_id)
              -- 1 undefined tile onscreen (it's foreground hiding leaf in PICO-8,
              --  but what matters here is that midground flag is not set)
              mock_mset(5, 0, 46)
              -- foreground tile to test foreground layer
              mock_mset(0, 1, grass_top_decoration1)

              state.curr_stage_data = {
                loop_exit_areas = {location_rect(-1, 0, 0, 2)},
                loop_entrance_areas = {location_rect(1, 0, 3, 4)},
                goal_x = 3000
              }
            end)

            after_each(function ()
              pico8:clear_map()

              stage_state.set_camera_with_origin:clear()
              stage_state.set_camera_with_region_origin:clear()
              spr:clear()
              map:clear()
            end)

            it('draw_onscreen_tiles should call spr on tiles present on screen (no condition, region (0, 0))', function ()
              state.loaded_map_region_coords = vector(0, 0)
              state.camera_pos = vector(0, 0)

              state:draw_onscreen_tiles()

              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))
              assert.spy(spr).was_called(4)
              assert.spy(spr).was_called_with(spring_left_id, 0, 0)
              assert.spy(spr).was_called_with(spring_left_id, 3 * 8, 0)
              assert.spy(spr).was_called_with(46, 5 * 8, 0)
              assert.spy(spr).was_called_with(grass_top_decoration1, 0, 8)
            end)

            it('draw_onscreen_tiles should call spr on tiles present on screen (with condition, region (0, 0))', function ()
              state.loaded_map_region_coords = vector(0, 0)
              state.camera_pos = vector(0, 0)

              state:draw_onscreen_tiles(function (i, j)
                -- just a condition that will only show first tile
                return i == 0 and j == 0
              end)

              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))
              assert.spy(spr).was_called(1)
              -- spring at (0, 0) on-screen
              assert.spy(spr).was_called_with(spring_left_id, 0, 0)
            end)

            it('draw_onscreen_tiles should call spr on tiles present on screen (no condition, region (0, 1))', function ()
              state.loaded_map_region_coords = vector(0, 1)
              -- camera pos doesn't need to be at tile_size * 32, it could be anywhere in the region (0, 1)
              --  but for this test, don't go too far as we must have the test tiles on-screen,
              --  and since there were originally placed for (0, 0) as in the test above,
              --  for the lower region everything is offset by 32 on y so we should be around (0, 32)
              state.camera_pos = vector(0, tile_size * 40)

              state:draw_onscreen_tiles()

              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))
              assert.spy(spr).was_called(4)
              assert.spy(spr).was_called_with(spring_left_id, 0, 0)
              assert.spy(spr).was_called_with(spring_left_id, 3 * 8, 0)
              assert.spy(spr).was_called_with(46, 5 * 8, 0)
              assert.spy(spr).was_called_with(grass_top_decoration1, 0, 8)
            end)

            it('draw_onscreen_tiles should call spr on tiles present on screen (with condition, region (0, 1))', function ()
              state.loaded_map_region_coords = vector(0, 1)
              state.camera_pos = vector(0, tile_size * 40)
              state:draw_onscreen_tiles(function (i, j)
                -- just a condition that will only show first tile
                return i == 0 and j == 0
              end)

              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))
              assert.spy(spr).was_called(1)
              -- spring at (0, 0) on-screen
              assert.spy(spr).was_called_with(spring_left_id, 0, 0)
            end)

            it('render_environment_midground should call map for all midground sprites', function ()
              -- note that we reverted to using map for performance, so this test doesn't need to be
              --  in the tile test data setup context anymore
              state.camera_pos = vector(0, 0)
              state.loaded_map_region_coords = vector(0, 0)

              state:render_environment_midground()

              assert.spy(stage_state.set_camera_with_region_origin).was_called(1)
              assert.spy(stage_state.set_camera_with_region_origin).was_called_with(match.ref(state))

              assert.spy(map).was_called(1)
              assert.spy(map).was_called_with(0, 0, 0, 0, map_region_tile_width, map_region_tile_height, sprite_masks.midground)

              -- we also draw the goal line, but it's prototype so we don't test it
            end)

            it('render_environment_foreground should call spr on tiles present on screen', function ()
              -- this test was not written before extracting draw_onscreen_tiles
              --  but it was copy-pasted from render_environment_midground
              state.camera_pos = vector(0, 0)
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
                -- spawn_new_emeralds has been stubbed in this context,
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

          -- unlike above, we test on_exit method itself here
          describe('on_exit', function ()

            setup(function ()
              stub(overlay, "clear_labels")
              stub(picosonic_app, "stop_all_coroutines")
              stub(stage_state, "stop_bgm")
              -- we don't really mind spying on spawn_new_emeralds
              --  but we do not want to spend 0.5s finding all of them
              --  in before_each every time due to on_enter,
              --  so we stub this
              stub(stage_state, "spawn_new_emeralds")
            end)

            teardown(function ()
              overlay.clear_labels:revert()
              picosonic_app.stop_all_coroutines:revert()
              stage_state.stop_bgm:revert()
              stage_state.spawn_new_emeralds:revert()
            end)

            after_each(function ()
              overlay.clear_labels:clear()
              stage_state.stop_bgm:clear()
              stage_state.spawn_new_emeralds:clear()
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
