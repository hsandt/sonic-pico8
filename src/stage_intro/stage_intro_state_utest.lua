require("test/bustedhelper_stage_intro")
require("common_stage_intro")
require("resources/visual_ingame_addon")  -- stage_intro mostly uses ingame visuals
require("resources/visual_stage_intro_addon")  -- for clouds

local stage_intro_state = require("stage_intro/stage_intro_state")

local coroutine_runner = require("engine/application/coroutine_runner")
local postprocess = require("engine/render/postprocess")
local overlay = require("engine/ui/overlay")

local picosonic_app = require("application/picosonic_app_stage_intro")
local stage_data = require("data/stage_data")
local stage_intro_data = require("data/stage_intro_data")
local base_stage_state = require("ingame/base_stage_state")
local camera_class = require("ingame/camera")
local player_char = require("ingame/playercharacter")
local visual_stage = require("resources/visual_stage")

describe('stage_intro_state', function ()

  describe('static members', function ()

    it('type is ":stage_intro"', function ()
      assert.are_equal(':stage_intro', stage_intro_state.type)
    end)

  end)

  describe('(with instance)', function ()

    local state

    before_each(function ()
      local app = picosonic_app()
      state = stage_intro_state()
      -- no need to register gamestate properly, just add app member to pass tests
      state.app = app
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
            ':stage_intro',
            stage_data[1],
            camera_class(),
            overlay(),
            postprocess(),
          },
          {
            state.type,
            state.curr_stage_data,
            state.camera,
            state.overlay,
            state.postproc,
          })
      end)

    end)

    describe('on_enter', function ()

      setup(function ()
        stub(camera_class, "setup_for_stage")
        stub(_G, "reload")
        stub(base_stage_state, "reload_sonic_spritesheet")
        stub(stage_intro_state, "spawn_player_char")
        stub(picosonic_app, "start_coroutine")
      end)

      teardown(function ()
        camera_class.setup_for_stage:revert()
        reload:revert()
        base_stage_state.reload_sonic_spritesheet:revert()
        stage_intro_state.spawn_player_char:revert()
        picosonic_app.start_coroutine:revert()
      end)

      after_each(function ()
        camera_class.setup_for_stage:clear()
        reload:clear()
        base_stage_state.reload_sonic_spritesheet:clear()
        stage_intro_state.spawn_player_char:clear()
        picosonic_app.start_coroutine:clear()
      end)

      it('should call setup_for_stage on camera with current stage data', function ()
        state:on_enter()

        assert.spy(camera_class.setup_for_stage).was_called(1)
        assert.spy(camera_class.setup_for_stage).was_called_with(match.ref(state.camera), state.curr_stage_data)
      end)

      it('should hardcode set loaded_map_region_coords', function ()
        state:on_enter()

        assert.are_equal(vector(0, 1), state.loaded_map_region_coords)
      end)

      it('should call reload for stage tiles, Sonic main sprites (general memory storage) and stage1, map 01 (hardcoded)', function ()
        state:on_enter()

        assert.spy(reload).was_called(2)
        assert.spy(reload).was_called_with(0x0, 0x0, 0x2000, "data_stage1_intro.p8")

        assert.spy(base_stage_state.reload_sonic_spritesheet).was_called(1)
        assert.spy(base_stage_state.reload_sonic_spritesheet).was_called_with(match.ref(state))

        assert.spy(reload).was_called_with(0x2000, 0x2000, 0x1000, "data_stage1_01.p8")
      end)

      it('should call spawn_player_char', function ()
        state:on_enter()

        assert.spy(stage_intro_state.spawn_player_char).was_called(1)
        assert.spy(stage_intro_state.spawn_player_char).was_called_with(match.ref(state))
      end)

      it('should assign spawned player char to camera target', function ()
        assert.are_equal(state.player_char, state.camera.target_pc)
      end)

      it('should call start_coroutine_method on play_intro_async', function ()
        state:on_enter()

        assert.spy(picosonic_app.start_coroutine).was_called(1)
        assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_intro_state.play_intro_async, match.ref(state))
      end)

    end)

    describe('update', function ()

      setup(function ()
        stub(player_char, "update")
        stub(camera_class, "update")
      end)

      teardown(function ()
        player_char.update:revert()
        camera_class.update:revert()
      end)

      after_each(function ()
        player_char.update:clear()
        camera_class.update:clear()
      end)

      it('should update player character, camera', function ()
        state.player_char = player_char()

        state:update()

        assert.spy(player_char.update).was_called(1)
        assert.spy(player_char.update).was_called_with(match.ref(state.player_char))

        assert.spy(camera_class.update).was_called(1)
        assert.spy(camera_class.update).was_called_with(match.ref(state.camera))
      end)

    end)

    describe('render', function ()

      setup(function ()
        stub(stage_intro_state, "render_background")  -- custom implementation
        stub(stage_intro_state, "render_stage_elements")
        stub(stage_intro_state, "render_overlay")
      end)

      teardown(function ()
        stage_intro_state.render_background:revert()
        stage_intro_state.render_stage_elements:revert()
        stage_intro_state.render_overlay:revert()
      end)

      after_each(function ()
        stage_intro_state.render_background:clear()
        stage_intro_state.render_stage_elements:clear()
        stage_intro_state.render_overlay:clear()
      end)

      it('should call render_background, render_stage_elements, render_overlay', function ()
        state:render()
        assert.spy(stage_intro_state.render_background).was_called(1)
        assert.spy(stage_intro_state.render_background).was_called_with(match.ref(state), state.camera.position)
        assert.spy(stage_intro_state.render_stage_elements).was_called(1)
        assert.spy(stage_intro_state.render_stage_elements).was_called_with(match.ref(state))
        assert.spy(stage_intro_state.render_overlay).was_called(1)
        assert.spy(stage_intro_state.render_overlay).was_called_with(match.ref(state))
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

      it('should call overlay:draw', function ()
        state:render_overlay()
        assert.spy(overlay.draw).was_called(1)
        assert.spy(overlay.draw).was_called_with(match.ref(state.overlay))
      end)

    end)

    describe('get_map_region_coords', function ()

      setup(function ()
        -- important to stub base method, not child override
        stub(base_stage_state, "get_map_region_coords", function (self)
          return vector(self.test_u, self.test_v)
        end)
      end)

      teardown(function ()
        base_stage_state.get_map_region_coords:revert()
      end)

      after_each(function ()
        base_stage_state.get_map_region_coords:clear()
      end)

      it('(u < 0) should return base_stage_state:get_map_region_coords maxed to 0', function ()
        -- Sonic falling, show fake infinite background
        state.test_u = -3.5
        state.test_v = 1
        assert.are_equal(vector(0, 1), state:get_map_region_coords())
      end)

      it('(u >= 0) should return base_stage_state:get_map_region_coords', function ()
        -- Sonic landing, show real ground
        state.test_u = 1
        state.test_v = 1
        assert.are_equal(vector(1, 1), state:get_map_region_coords())
      end)

      it('(v < 0) should return base_stage_state:get_map_region_coords with v UNCLAMPED to allow reload_map_region to apply modulo 1 later', function ()
        -- Sonic falling, show fake infinite background
        state.test_u = 0
        state.test_v = -3.5
        assert.are_equal(vector(0, -3.5), state:get_map_region_coords())
      end)

      it('(v >= 0) should return base_stage_state:get_map_region_coords with v clamped to stage limit = 1 (optional)', function ()
        -- Sonic landing, show real ground
        state.test_v = 2
        assert.are_equal(vector(0, 1), state:get_map_region_coords())
      end)

    end)

    describe('reload_map_region', function ()

      setup(function ()
        stub(_G, "reload")
        stub(base_stage_state, "reload_vertical_half_of_map_region")
        stub(base_stage_state, "reload_horizontal_half_of_map_region")
        stub(base_stage_state, "reload_quarter_of_map_region")
      end)

      teardown(function ()
        _G.reload:revert()
        base_stage_state.reload_vertical_half_of_map_region:revert()
        base_stage_state.reload_horizontal_half_of_map_region:revert()
        base_stage_state.reload_quarter_of_map_region:revert()
      end)

      -- on_enter calls check_reload_map_region, so reset count for all reload utility methods
      before_each(function ()
        _G.reload:clear()
        base_stage_state.reload_vertical_half_of_map_region:clear()
        base_stage_state.reload_horizontal_half_of_map_region:clear()
        base_stage_state.reload_quarter_of_map_region:clear()

        state.curr_stage_id = 1
      end)

      -- test various coordinates from negative v with wrapping to no wrapping

      it('(wrapping) should call reload_vertical_half_of_map_region for map 00 and 00 again for region coords (0, -1.5) (swapping)', function ()
        state:reload_map_region(vector(0, -1.5))

        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called(2)
        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.up, "data_stage1_00.p8")
        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.down, "data_stage1_00.p8")
      end)

      it('(wrapping) should call reload for map 00 for region coords (0, -1)', function ()
        state:reload_map_region(vector(0, -1))

        assert.spy(reload).was_called(1)
        assert.spy(reload).was_called_with(0x2000, 0x2000, 0x1000, "data_stage1_00.p8")
      end)

      it('(wrapping) should call reload_vertical_half_of_map_region for map 00 and 00 again for region coords (0, -0.5) (swapping)', function ()
        state:reload_map_region(vector(0, -0.5))

        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called(2)
        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.up, "data_stage1_00.p8")
        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.down, "data_stage1_00.p8")
      end)

      it('(wrapping) should call reload for map 00 for region coords (0, 0)', function ()
        state:reload_map_region(vector(0, 0))

        assert.spy(reload).was_called(1)
        assert.spy(reload).was_called_with(0x2000, 0x2000, 0x1000, "data_stage1_00.p8")
      end)

      it('(no wrapping) should call reload_vertical_half_of_map_region for map 00 and 01 for region coords (0, 0.5)', function ()
        state:reload_map_region(vector(0, 0.5))

        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called(2)
        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.up, "data_stage1_00.p8")
        assert.spy(base_stage_state.reload_vertical_half_of_map_region).was_called_with(match.ref(state), vertical_dirs.down, "data_stage1_01.p8")
      end)

      it('(no wrapping) should call reload for map 01 for region coords (0, 1)', function ()
        state:reload_map_region(vector(0, 1))

        assert.spy(reload).was_called(1)
        assert.spy(reload).was_called_with(0x2000, 0x2000, 0x1000, "data_stage1_01.p8")
      end)

      it('should set loaded_map_region_coords to the passed region', function ()
        state.loaded_map_region_coords = vector(0, 0)

        state:reload_map_region(vector(1, 0.5))

        assert.are_equal(vector(1, 0.5), state.loaded_map_region_coords)
      end)

    end)

    describe('show_stage_splash_async', function ()

      local corunner

      before_each(function ()
        corunner = coroutine_runner()
        corunner:start_coroutine(stage_intro_state.show_stage_splash_async, state)
      end)

      -- this coroutine become more complex, so only test it doesn't crash
      it('show_stage_splash_async should not crash', function ()
        -- a time long enough to cover initial delay then full animation
        for i = 1, stage_intro_data.show_stage_splash_delay * state.app.fps - 1 + 160 do
          corunner:update_coroutines()
        end
      end)

    end)

  end)  -- (with instance)

end)
