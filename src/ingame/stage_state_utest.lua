require("test/bustedhelper_ingame")

local stage_state = require("ingame/stage_state")

local coroutine_runner = require("engine/application/coroutine_runner")
local flow = require("engine/application/flow")
local location_rect = require("engine/core/location_rect")
local animated_sprite = require("engine/render/animated_sprite")

local picosonic_app = require("application/picosonic_app_ingame")
local camera_data = require("data/camera_data")
local stage_common_data = require("data/stage_common_data")
local stage_data = require("data/stage_data")
local base_stage_state = require("ingame/base_stage_state")
local camera_class = require("ingame/camera")
local emerald = require("ingame/emerald")
local emerald_fx = require("ingame/emerald_fx")
local goal_plate = require("ingame/goal_plate")
local player_char = require("ingame/playercharacter")
local spring = require("ingame/spring")
local emerald_common = require("render/emerald_common")
local audio = require("resources/audio")
local visual = require("resources/visual_common")
local visual_ingame_data = require("resources/visual_ingame_numerical_data")
local visual_stage = require("resources/visual_stage")

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

    describe('init', function ()

      setup(function ()
        -- base constructor is important, do not stub it (although we are not checking
        --  base members below so it could work with stub too)
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
            ':stage',
            1,
            stage_data[1],
            nil,
            false,
            {},
            {},
            {},
            {},
            {},
            {},
            nil,
            -- itest only
            true,
          },
          {
            state.type,
            state.curr_stage_id,
            state.curr_stage_data,
            state.player_char,
            state.has_player_char_reached_goal,
            state.spawned_emerald_locations,
            state.emeralds,
            state.picked_emerald_numbers_set,
            state.emerald_pick_fxs,
            state.overlap_tiles,
            state.springs,
            state.loaded_map_region_coords,
            -- itest only
            state.enable_spawn_objects,
          })
      end)

    end)

    describe('_tostring', function ()

      it('should return "stage_state(1)"', function ()
        assert.are_equal("stage_state(1)", state:_tostring())
      end)

    end)

    describe('on_enter', function ()

      setup(function ()
        stub(stage_state, "reload_runtime_data")
        stub(stage_state, "spawn_player_char")
        stub(stage_state, "play_bgm")
        stub(stage_state, "spawn_objects_in_all_map_regions")
        stub(stage_state, "restore_picked_emerald_data")
        stub(camera_class, "setup_for_stage")
        stub(base_stage_state, "check_reload_map_region")
      end)

      teardown(function ()
        stage_state.reload_runtime_data:revert()
        stage_state.spawn_player_char:revert()
        stage_state.play_bgm:revert()
        stage_state.spawn_objects_in_all_map_regions:revert()
        stage_state.restore_picked_emerald_data:revert()
        camera_class.setup_for_stage:revert()
        base_stage_state.check_reload_map_region:revert()
      end)

      after_each(function ()
        stage_state.reload_runtime_data:clear()
        stage_state.spawn_player_char:clear()
        stage_state.play_bgm:clear()
        stage_state.spawn_objects_in_all_map_regions:clear()
        stage_state.restore_picked_emerald_data:clear()
        camera_class.setup_for_stage:clear()
        base_stage_state.check_reload_map_region:clear()
      end)

      before_each(function ()
        state:on_enter()
      end)

      it('should call spawn_objects_in_all_map_regions', function ()
        assert.spy(state.spawn_objects_in_all_map_regions).was_called(1)
        assert.spy(state.spawn_objects_in_all_map_regions).was_called_with(match.ref(state))
      end)

      it('should call restore_picked_emerald_data', function ()
        assert.spy(state.restore_picked_emerald_data).was_called(1)
        assert.spy(state.restore_picked_emerald_data).was_called_with(match.ref(state))
      end)

      it('should call setup_for_stage on camera with current stage data', function ()
        assert.spy(camera_class.setup_for_stage).was_called(1)
        assert.spy(camera_class.setup_for_stage).was_called_with(match.ref(state.camera), state.curr_stage_data)
      end)

      it('should call check_reload_map_region', function ()
        assert.spy(state.check_reload_map_region).was_called(1)
        assert.spy(state.check_reload_map_region).was_called_with(match.ref(state))
      end)

      it('should call reload_runtime_data', function ()
        assert.spy(state.reload_runtime_data).was_called(1)
        assert.spy(state.reload_runtime_data).was_called_with(match.ref(state))
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

      it('should call play_bgm', function ()
        assert.spy(state.play_bgm).was_called(1)
        assert.spy(state.play_bgm).was_called_with(match.ref(state))
      end)

    end)

    describe('reload_runtime_data', function ()

      setup(function ()
        stub(_G, "reload")
      end)

      teardown(function ()
        reload:revert()
      end)

      after_each(function ()
        reload:clear()
      end)

      it('should all stage runtime data copy Sonic sprite variants into general memory for quick runtime reload', function ()
        state:reload_runtime_data()

        -- note that debug_collision_mask adds an extra reload for collision masks,
        --  but we stripped it from busted by surrounding it with #pico8
        assert.spy(reload).was_called(18)

        -- general runtime data
        assert.spy(reload).was_called_with(0x0, 0x0, 0x2000, "data_stage1_ingame.p8")

        -- sprites occupying full rows
        assert.spy(reload).was_called_with(0x4b00, 0x400, 0x1000, "data_stage_sonic.p8")

        -- spin dash sprites
        -- just test the first iterations...
        assert.spy(reload).was_called_with(0x5b00, 0x1400, 0x28, "data_stage_sonic.p8")
        assert.spy(reload).was_called_with(0x5b28, 0x1440, 0x28, "data_stage_sonic.p8")
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
        --    |  X
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

    describe('spawn_emerald_at', function ()

      it('should store emerald global location', function ()
        state.loaded_map_region_coords = vector(1, 0.5)

        state:spawn_emerald_at(location(128 + 5, 16 + 17))

        assert.are_same({
          location(128 + 5, 16 + 17),
        }, state.spawned_emerald_locations)
      end)

      it('should spawn and store emerald objects for each emerald tile', function ()
        state.loaded_map_region_coords = vector(1, 0.5)

        state:spawn_emerald_at(location(128 + 5, 16 + 17))

        assert.are_same({
          emerald(1, location(128 + 5, 16 + 17)),
        }, state.emeralds)
      end)

      it('(no hiding leaves on the right) should not add overlap tile hiding leaves on emerald location', function ()
        state.loaded_map_region_coords = vector(1, 0.5)

        state:spawn_emerald_at(location(128 + 5, 16 + 17))

        assert.are_same({}, state.overlap_tiles)
      end)

      it('(hiding leaves on the right) should add overlap tile hiding leaves on emerald location', function ()
        state.loaded_map_region_coords = vector(1, 0.5)
        -- region coords: place hiding leaves just on right of emerald
        mset(5 + 1, 17, visual_ingame_data.hiding_leaves_id)
        state.overlap_tiles = {"dummy"}

        -- '128 +' and '16 +' because region u = 1 and v = 0.5 (we could also write 33 = 32 + 1, but
        --  16 is the real reference = topleft.j for v = 0.5)
        state:spawn_emerald_at(location(128 + 5, 16 + 17))

        assert.are_same({"dummy", {location(128 + 5, 16 + 17), visual_ingame_data.hiding_leaves_id}}, state.overlap_tiles)
      end)

    end)

    describe('spawn_palm_tree_leaves', function ()

      it('should spawn and store palm tree leaves core at global location', function ()
        state:spawn_palm_tree_leaves_at(location(1, 33))

        assert.are_same({
          location(1, 33),
        }, state.palm_tree_leaves_core_global_locations)
      end)

    end)

    describe('spawn_goal_plate_at', function ()

      it('should spawn and store goal plate core at global location', function ()
        state:spawn_goal_plate_at(location(1, 33))

        assert.are_same(goal_plate(location(1, 33)), state.goal_plate)
      end)

    end)

    describe('spawn_spring_up_at', function ()

      it('should spawn and store spring up at global location', function ()
        state:spawn_spring_up_at(location(1, 33))

        assert.are_same({spring(directions.up, location(1, 33))}, state.springs)
      end)

    end)

    describe('spawn_spring_left_at', function ()

      it('should spawn and store spring left at global location', function ()
        state:spawn_spring_left_at(location(1, 33))

        assert.are_same({spring(directions.left, location(1, 33))}, state.springs)
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

    describe('get_spawn_object_callback', function ()

      it('should return stage_state.spawn_emerald_at for visual.emerald_repr_sprite_id', function ()
        assert.are_equal(stage_state.spawn_emerald_at, state:get_spawn_object_callback(visual.emerald_repr_sprite_id))
      end)

      it('should return stage_state.spawn_palm_tree_leaves_at for visual_ingame_data.palm_tree_leaves_core_id', function ()
        assert.are_equal(stage_state.spawn_palm_tree_leaves_at, state:get_spawn_object_callback(visual_ingame_data.palm_tree_leaves_core_id))
      end)

      it('should return stage_state.spawn_goal_plate_at for visual_ingame_data.goal_plate_base_id', function ()
        assert.are_equal(stage_state.spawn_goal_plate_at, state:get_spawn_object_callback(visual_ingame_data.goal_plate_base_id))
      end)

    end)

    -- we stub spawn_objects_in_all_map_regions in (stage state entered) region, so test it outside
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

    -- we stub restore_picked_emerald_data in (stage state entered) region, so test it outside
    describe('restore_picked_emerald_data', function ()

      before_each(function ()
        -- 0b01001001 -> 73 (low-endian, so lowest bit is for emerald 1)
        poke(0x5dff, 73)
      end)

      after_each(function ()
        poke(0x5dff, 0)
      end)

      it('should read 1 byte in general memory representing picked emeralds bitset', function ()
        state:restore_picked_emerald_data()

        assert.are_same({
          [1] = true,
          [4] = true,
          [7] = true,
        }, state.picked_emerald_numbers_set)
      end)

      it('should delete emerald object for every picked emerald', function ()
        state.emeralds = {"dummy1", "dummy2", "dummy3", "dummy4", "dummy5", "dummy6", "dummy7", "dummy8"}

        state:restore_picked_emerald_data()

        assert.are_same({"dummy2", "dummy3", "dummy5", "dummy6", "dummy8"}, state.emeralds)
      end)

      it('should clear picked emerald transitional memory', function ()
        state:restore_picked_emerald_data()

        assert.are_equal(0, peek(0x5dff))
      end)

    end)

    describe('(stage states added)', function ()

      before_each(function ()
        flow:add_gamestate(state)
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

          -- restore_picked_emerald_data relies on peek which will find nil memory if not set
          -- so stub it
          stub(stage_state, "restore_picked_emerald_data")
        end)

        teardown(function ()
          stage_state.spawn_objects_in_all_map_regions:revert()
          stage_state.restore_picked_emerald_data:revert()
        end)

        after_each(function ()
          stage_state.spawn_objects_in_all_map_regions:clear()
          stage_state.restore_picked_emerald_data:clear()
        end)

        before_each(function ()
          flow:change_state(state)
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
              emerald_fx(1, vector(0, 0), visual.animated_sprite_data_t.emerald_pick_fx),
              emerald_fx(2, vector(12, 4), visual.animated_sprite_data_t.emerald_pick_fx)
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
              emerald_fx(1, vector(999, 1), visual.animated_sprite_data_t.emerald_pick_fx),
              emerald_fx(2, vector(2, 2), visual.animated_sprite_data_t.emerald_pick_fx),
              emerald_fx(3, vector(999, 3), visual.animated_sprite_data_t.emerald_pick_fx)
            }

            state:update_fx()

            assert.are_same({
              emerald_fx(2, vector(2, 2), visual.animated_sprite_data_t.emerald_pick_fx)
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
              emerald_fx(1, vector(0, 0), visual.animated_sprite_data_t.emerald_pick_fx),
              emerald_fx(2, vector(12, 4), visual.animated_sprite_data_t.emerald_pick_fx)
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
            stub(spring, "update")
            stub(player_char, "update")
            stub(stage_state, "check_reached_goal")
            stub(goal_plate, "update")
            stub(camera_class, "update")
          end)

          teardown(function ()
            stage_state.update_fx:revert()
            spring.update:revert()
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
            stub(base_stage_state, "check_reload_map_region")
          end)

          after_each(function ()
            stage_state.update_fx:clear()
            spring.update:clear()
            player_char.update:clear()
            stage_state.check_reached_goal:clear()
            goal_plate.update:clear()
            camera_class.update:clear()

            base_stage_state.check_reload_map_region:revert()
          end)

          it('should call fx and character update, check_reached_goal, goal update, camera update, check_reload_map_region', function ()
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
            assert.spy(base_stage_state.check_reload_map_region).was_called(1)
            assert.spy(base_stage_state.check_reload_map_region).was_called_with(match.ref(state))
          end)

          it('should not try to update goal if no goal plate found (safety check for itests)', function ()
            state.goal_plate = nil

            state:update()

            assert.spy(goal_plate.update).was_not_called()
          end)

          describe('update', function ()

            it('should update each spring', function ()
              state.springs = {
                spring(directions.up, location(1, 1)),
                spring(directions.left, location(2, 2)),
              }

              state:update()

              assert.spy(spring.update).was_called(2)
              assert.spy(spring.update).was_called_with(match.ref(state.springs[1]))
              assert.spy(spring.update).was_called_with(match.ref(state.springs[2]))
            end)

          end)

        end)  -- update

        describe('render', function ()

          setup(function ()
            stub(visual_stage, "render_background")
            stub(stage_state, "render_stage_elements")
            stub(stage_state, "render_fx")
            stub(stage_state, "render_hud")
            stub(stage_state, "render_emerald_cross")
          end)

          teardown(function ()
            visual_stage.render_background:revert()
            stage_state.render_stage_elements:revert()
            stage_state.render_fx:revert()
            stage_state.render_hud:revert()
            stage_state.render_emerald_cross:revert()
          end)

          after_each(function ()
            visual_stage.render_background:clear()
            stage_state.render_stage_elements:clear()
            stage_state.render_fx:clear()
            stage_state.render_hud:clear()
            stage_state.render_emerald_cross:clear()
          end)

          it('should call render_background, render_stage_elements, render_fx, render_hud', function ()
            -- to test camera position flooring
            state.camera:init_position(vector(60.1, 380.9))

            state:render()

            assert.spy(visual_stage.render_background).was_called(1)
            assert.spy(visual_stage.render_background).was_called_with(vector(60, 380))  -- floored coords
            assert.spy(stage_state.render_stage_elements).was_called(1)
            assert.spy(stage_state.render_stage_elements).was_called_with(match.ref(state))
            assert.spy(stage_state.render_fx).was_called(1)
            assert.spy(stage_state.render_fx).was_called_with(match.ref(state))
            assert.spy(stage_state.render_hud).was_called(1)
            assert.spy(stage_state.render_hud).was_called_with(match.ref(state))
          end)

        end)  -- state.render

        describe('check_player_char_in_spring_trigger_area', function ()

          before_each(function ()
            state.springs = {
              spring(directions.up, location(0, 0)),
              spring(directions.left, location(0, 1)),
              spring(directions.right, location(0, 2)),
            }
          end)

          it('should return nil when player char position is too far from all the springs', function ()
            state.player_char.position = vector(300, 300)
            assert.is_nil(state:check_player_char_in_spring_trigger_area())
          end)

          it('should return spring when player char is standing on spring up (left edge)', function ()
            -- set bottom center manually (spring pivot at (10, 2))
            state.player_char.position = vector(10 - 8, 2.1 - 8)

            local spring_obj = state:check_player_char_in_spring_trigger_area()

            assert.is_not_nil(spring_obj)
            assert.are_equal(state.springs[1], spring_obj)
          end)

          it('should return spring when player char is standing on spring up (right edge)', function ()
            -- set bottom center manually (spring pivot at (10, 2))
            state.player_char.position = vector(10 + 8.9, 2.1 - 8)

            local spring_obj = state:check_player_char_in_spring_trigger_area()

            assert.is_not_nil(spring_obj)
            assert.are_equal(state.springs[1], spring_obj)
          end)

          it('should return spring when player char is touching spring left (top)', function ()
            -- set bottom center manually (spring pivot at (10, 10))
            state.player_char.position = vector(10 - 11, 10 - 6)

            local spring_obj = state:check_player_char_in_spring_trigger_area()

            assert.is_not_nil(spring_obj)
            assert.are_equal(state.springs[2], spring_obj)
          end)

          it('should return spring when player char is touching spring left (bottom)', function ()
            -- set bottom center manually (spring pivot at (10, 10))
            state.player_char.position = vector(10 - 11, 10 + 6.9)

            local spring_obj = state:check_player_char_in_spring_trigger_area()

            assert.is_not_nil(spring_obj)
            assert.are_equal(state.springs[2], spring_obj)
          end)

          it('should return spring when player char is touching spring right (top)', function ()
            -- set bottom center manually (spring pivot at (5, 18)), we ceil 3.5 so +4
            state.player_char.position = vector(5 + 4, 18 - 6)

            local spring_obj = state:check_player_char_in_spring_trigger_area()

            assert.is_not_nil(spring_obj)
            assert.are_equal(state.springs[3], spring_obj)
          end)

          it('should return spring when player char is touching spring right (bottom)', function ()
            -- set bottom center manually (spring pivot at (5, 18)), we ceil 3.5 so +4
            state.player_char.position = vector(5 + 4, 18 + 6.9)

            local spring_obj = state:check_player_char_in_spring_trigger_area()

            assert.is_not_nil(spring_obj)
            assert.are_equal(state.springs[3], spring_obj)
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

          -- we need to stub start_coroutine on the child class,
          --  not gameapp, or calls won't be monitored

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
              emerald(8, location(0, 1)),
            }
          end)

          it('should add an emerald number to the picked set', function ()
            state.picked_emerald_numbers_set = {
              [4] = true
            }
            state:character_pick_emerald(state.emeralds[2])
            assert.are_same({[2] = true, [4] = true}, state.picked_emerald_numbers_set)
          end)

          it('should create a pick FX and play it', function ()
            state.emerald_pick_fxs = {
              emerald_fx(1, vector(0, 0), visual.animated_sprite_data_t.emerald_pick_fx)
            }

            state:character_pick_emerald(state.emeralds[3])

            -- emerald 2 was at location (0, 1),
            --  so its center was at (4, 12)
            assert.are_same({
                emerald_fx(1, vector(0, 0), visual.animated_sprite_data_t.emerald_pick_fx),
                emerald_fx(8, vector(4 + 5, 12), visual.animated_sprite_data_t.emerald_pick_fx)  -- pfx also follow emerald 8 center adjustment of X+5
              },
              state.emerald_pick_fxs)
          end)

          it('should remove an emerald from the sequence', function ()
            state:character_pick_emerald(state.emeralds[2])
            assert.are_same({emerald(1, location(0, 0)), emerald(8, location(0, 1))}, state.emeralds)
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

        describe('on_reached_goal_async', function ()

          -- removed actual tests, too hard to maintain
          -- instead, just run it and see if it crashes

          local corunner

          setup(function ()
            stub(_G, "load")
          end)

          teardown(function ()
            _G.load:revert()
          end)

          before_each(function ()
            _G.load:clear()

            state.goal_plate = goal_plate(location(100, 0))
            state.spawned_emerald_locations = {1, 2, 3, 4, 5, 6, 7, 8}

            corunner = coroutine_runner()
            corunner:start_coroutine(stage_state.on_reached_goal_async, state)
          end)

          it('should not crash with a few emeralds', function ()
            state.emeralds = {5, 6, 7, 8}

            -- a time long enough to cover everything until load()
            for i = 1, 1000 do
              corunner:update_coroutines()
            end
          end)

          it('should not crash with all emeralds', function ()
            state.emeralds = {}

            -- a time long enough to cover everything until load()
            for i = 1, 1000 do
              corunner:update_coroutines()
            end
          end)

        end)

        describe('store_picked_emerald_data', function ()

          it('should store 1 byte in general memory representing picked emeralds bitset', function ()
            state.picked_emerald_numbers_set = {
              [1] = true,
              [4] = true,
              [7] = true,
            }
            -- 0b01001001 -> 73 (low-endian, so lowest bit is for emerald 1)
            state:store_picked_emerald_data()
            assert.are_equal(73, peek(0x5dff))
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

        describe('render_stage_elements', function ()

          setup(function ()
            stub(stage_state, "render_environment_midground")
            stub(stage_state, "render_emeralds")
            stub(stage_state, "render_springs")
            stub(stage_state, "render_goal_plate")
            stub(stage_state, "render_player_char")
            stub(stage_state, "render_environment_foreground")
            stub(stage_state, "debug_render_trigger")
            stub(player_char, "debug_draw_tile_collision_masks")
            stub(player_char, "debug_draw_rays")
          end)

          teardown(function ()
            stage_state.render_environment_midground:revert()
            stage_state.render_emeralds:revert()
            stage_state.render_springs:revert()
            stage_state.render_goal_plate:revert()
            stage_state.render_player_char:revert()
            stage_state.render_environment_foreground:revert()
            stage_state.debug_render_trigger:revert()
            player_char.debug_draw_tile_collision_masks:revert()
            player_char.debug_draw_rays:revert()
          end)

          after_each(function ()
            stage_state.render_environment_midground:clear()
            stage_state.render_emeralds:clear()
            stage_state.render_springs:clear()
            stage_state.render_goal_plate:clear()
            stage_state.render_player_char:clear()
            stage_state.render_environment_foreground:clear()
            stage_state.debug_render_trigger:clear()
            player_char.debug_draw_tile_collision_masks:clear()
            player_char.debug_draw_rays:clear()
          end)

          it('should call render methods on everything in the stage', function ()
            state:render_stage_elements()
            assert.spy(state.render_environment_midground).was_called(1)
            assert.spy(state.render_environment_midground).was_called_with(match.ref(state))
            assert.spy(state.render_emeralds).was_called(1)
            assert.spy(state.render_emeralds).was_called_with(match.ref(state))
            assert.spy(state.render_springs).was_called(1)
            assert.spy(state.render_springs).was_called_with(match.ref(state))
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
            -- #debug_collision_mask only
            assert.spy(player_char.debug_draw_tile_collision_masks).was_called(1)
            assert.spy(player_char.debug_draw_tile_collision_masks).was_called_with(match.ref(state.player_char))
            -- #debug_collision_mask only end
            -- #debug_character only
            assert.spy(player_char.debug_draw_rays).was_called(1)
            assert.spy(player_char.debug_draw_rays).was_called_with(match.ref(state.player_char))
            -- #debug_character only end
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
            -- We could stub emerald:get_render_bounding_corners AND
            --  camera_class:is_rect_visible but chained stubbing often generates
            --  meaningless intermediate mock values. Instead, we do a mini-integration test
            --  with actual values where springs would be visible on screen or not
            --  (but we are not unit testing the visibility test itself, so no need to
            --  test all edge cases)
            state.emeralds = {
              emerald(1, location(1, 0)),
              emerald(2, location(2, 0)),
              emerald(3, location(8, 0)),  -- on right edge of screen, not visible
            }
            state.camera:init_position(vector(0, 0))

            state:render_emeralds()

            assert.spy(stage_state.set_camera_with_origin).was_called(1)
            assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
            assert.spy(emerald.render).was_called(2)
            assert.spy(emerald.render).was_called_with(match.ref(state.emeralds[1]))
            assert.spy(emerald.render).was_called_with(match.ref(state.emeralds[2]))
          end)

        end)

        describe('render_springs', function ()

          setup(function ()
            stub(stage_state, "set_camera_with_origin")
            stub(spring, "render")
          end)

          teardown(function ()
            stage_state.set_camera_with_origin:revert()
            spring.render:revert()
          end)

          after_each(function ()
            stage_state.set_camera_with_origin:clear()
            spring.render:clear()
          end)

          it('should call set_camera_with_origin and spring:render', function ()
            -- we prefer mini-integration test as with render_emeralds
            state.springs = {
              spring(directions.up, location(1, 0)),
              spring(directions.left, location(2, 0)),
              spring(directions.right, location(8, 0)),  -- on right edge of screen, not visible
            }
            state.camera:init_position(vector(0, 0))

            state:render_springs()

            assert.spy(stage_state.set_camera_with_origin).was_called(1)
            assert.spy(stage_state.set_camera_with_origin).was_called_with(match.ref(state))
            assert.spy(spring.render).was_called(2)
            assert.spy(spring.render).was_called_with(match.ref(state.springs[1]))
            assert.spy(spring.render).was_called_with(match.ref(state.springs[2]))
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
            stub(emerald_common, "draw")
            stub(player_char, "debug_print_info")
          end)

          teardown(function ()
            emerald_common.draw:revert()
            player_char.debug_print_info:revert()
          end)

          after_each(function ()
            emerald_common.draw:clear()
            player_char.debug_print_info:clear()
          end)

          it('should call emerald_common.draw for each emerald, true color for picked ones and silhouette for unpicked ones', function ()
            state.spawned_emerald_locations = {
              -- dummy values just to have correct count (3, counting hole on 2)
              location(1, 1), location(2, 2), location(3, 3)
            }
            state.picked_emerald_numbers_set = {
              [1] = true,
              [3] = true
            }

            state:render_hud()

            assert.spy(emerald_common.draw).was_called(3)
            assert.spy(emerald_common.draw).was_called_with(1, vector(4, 3))
            -- silhouette only
            assert.spy(emerald_common.draw).was_called_with(-1, vector(12, 3))
            assert.spy(emerald_common.draw).was_called_with(3, vector(20, 3))
          end)

          it('should debug render character info (#debug_character only)', function ()
            state:render_hud()

            assert.spy(player_char.debug_print_info).was_called(1)
            assert.spy(player_char.debug_print_info).was_called_with(match.ref(state.player_char))
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

          it('reload_bgm_tracks should reload sfx from bgm cartridge', function ()
            state:reload_bgm_tracks()

            assert.spy(reload).was_called(1)
            assert.spy(reload).was_called_with(0x3420, 0x3420, 0xc38, "picosonic_ingame.p8")
          end)

          it('play_bgm should start level bgm', function ()
            state:play_bgm()

            assert.are_same({music=stage_common_data.bgm_id, fadems=0, channel_mask=(1 << 0) + (1 << 1) + (1 << 2)}, pico8.current_music)
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

        -- unlike above, we test on_exit method itself here
        -- now commented out to spare tokens, as we never use it
        --[[
        describe('on_exit', function ()

          setup(function ()
            stub(picosonic_app, "stop_all_coroutines")
            stub(stage_state, "stop_bgm")
          end)

          teardown(function ()
            picosonic_app.stop_all_coroutines:revert()
            stage_state.stop_bgm:revert()
          end)

          after_each(function ()
            stage_state.stop_bgm:clear()
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

          it('should reset pico8 camera', function ()
            assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
          end)

          it('should call stop_bgm', function ()
            assert.spy(stage_state.stop_bgm).was_called(1)
            assert.spy(stage_state.stop_bgm).was_called_with(match.ref(state))
          end)

        end)
        --]]

      end)  -- (stage state entered)

    end)  -- (stage states added)

  end)  -- (with instance)

end)
