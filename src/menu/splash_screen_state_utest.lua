require("test/bustedhelper_titlemenu")
local splash_screen_state = require("menu/splash_screen_state")

local menu = require("menu/menu")

describe('splash_screen_state', function ()

  describe('(with instance)', function ()

    local fake_app = {start_coroutine = function () return 0 end}
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

      it('should reload extra gfx top half for splash screen', function ()
        state:on_enter()

        assert.spy(reload).was_called(1)
        assert.spy(reload).was_called_with(0x0, 0x0, 0x1000, "data_stage1_01.p8")
      end)

    end)

    describe('update', function ()

    end)

    describe('render', function ()

      it('should not crash', function ()
        state:render()
      end)

    end)

    describe('draw_speed_lines', function ()

      it('should not crash', function ()
        state:draw_speed_lines()
      end)

    end)

  end)  -- (with instance)

end)
