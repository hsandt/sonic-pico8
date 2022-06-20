require("test/bustedhelper_titlemenu")
local splash_screen_state = require("menu/splash_screen_state")

local menu = require("menu/menu")

describe('splash_screen_state', function ()

  describe('(with instance)', function ()

    local fake_app = {}
    local state

    before_each(function ()
      state = splash_screen_state()
      state.app = fake_app
    end)

    describe('on_enter', function ()

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

      it('should reload extra gfx for splash screen', function ()
        state:on_enter()

        assert.spy(reload).was_called(1)
        assert.spy(reload).was_called_with(0x0, 0x0, 0x2000, "data_stage1_01.p8")
      end)

    end)

    describe('update', function ()

    end)

    describe('render', function ()

      setup(function ()
        stub(splash_screen_state, "draw_splash_screen_logo")
        stub(menu, "draw")
      end)

      teardown(function ()
        splash_screen_state.draw_splash_screen_logo:revert()
        menu.draw:revert()
      end)

      after_each(function ()
        splash_screen_state.draw_splash_screen_logo:clear()
        menu.draw:clear()
      end)

      it('should draw title', function ()
        state:render()

        assert.spy(splash_screen_state.draw_splash_screen_logo).was_called(1)
        assert.spy(splash_screen_state.draw_splash_screen_logo).was_called_with(match.ref(state))
      end)

    end)

  end)  -- (with instance)

end)
