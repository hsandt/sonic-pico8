require("test/bustedhelper_stage_intro")
require("common_stage_intro")
require("resources/visual_ingame_addon")  -- stage_intro mostly uses ingame visuals

local stage_intro_state = require("stage_intro/stage_intro_state")

local coroutine_runner = require("engine/application/coroutine_runner")
local postprocess = require("engine/render/postprocess")
local overlay = require("engine/ui/overlay")

local picosonic_app = require("application/picosonic_app_stage_intro")
local stage_data = require("data/stage_data")
local stage_intro_data = require("data/stage_intro_data")

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

      it('should initialize members', function ()
        assert.are_same({
            ':stage_intro',
            stage_data.for_stage[1],
            overlay(),
            postprocess(),
          },
          {
            state.type,
            state.curr_stage_data,
            state.overlay,
            state.postproc,
          })
      end)

    end)

    describe('on_enter', function ()

      setup(function ()
        stub(picosonic_app, "start_coroutine")
      end)

      teardown(function ()
        picosonic_app.start_coroutine:revert()
      end)

      after_each(function ()
        picosonic_app.start_coroutine:clear()
      end)

      it('should call start_coroutine_method on show_stage_splash_async', function ()
        state:on_enter()

        assert.spy(picosonic_app.start_coroutine).was_called(1)
        assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(state.app), stage_intro_state.show_stage_splash_async, match.ref(state))
      end)

    end)

    describe('render', function ()

      setup(function ()
        stub(stage_intro_state, "render_overlay")
      end)

      teardown(function ()
        stage_intro_state.render_overlay:revert()
      end)

      after_each(function ()
        stage_intro_state.render_overlay:clear()
      end)

      it('should call render_overlay', function ()
        state:render()
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
