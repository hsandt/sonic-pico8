require("test/bustedhelper_titlemenu")
local credits = require("menu/credits")

local menu = require("menu/menu")

describe('credits', function ()

  describe('(with instance)', function ()

    local fake_app = {}
    local c

    before_each(function ()
      c = credits()
      c.app = fake_app
    end)

    describe('on_enter', function ()

      setup(function ()
        stub(_G, "music")
        stub(menu, "show_items")
      end)

      teardown(function ()
        music:revert()
        menu.show_items:revert()
      end)

      before_each(function ()
        c = credits()
        c.app = fake_app
      end)

      after_each(function ()
        music:clear()
        menu.show_items:clear()
      end)

      it('should stop music', function ()
        c:on_enter()

        assert.spy(music).was_called(1)
        assert.spy(music).was_called_with(-1)
      end)

    end)

    describe('(with menu entered)', function ()

      before_each(function ()
        c:on_enter()
      end)

      describe('render', function ()

        setup(function ()
          stub(credits, "draw_credits_text")
          stub(menu, "draw")
        end)

        teardown(function ()
          credits.draw_credits_text:revert()
          menu.draw:revert()
        end)

        after_each(function ()
          credits.draw_credits_text:clear()
          menu.draw:clear()
        end)

        it('should draw title', function ()
          c:render()

          assert.spy(credits.draw_credits_text).was_called(1)
          assert.spy(credits.draw_credits_text).was_called_with(match.ref(c))
        end)

      end)

      describe('draw_credits_text', function ()

        it('should not error', function ()
          -- prefer direct call with no assert to assert.has_no_errors,
          --  because it tends to show a better, jumpable error message in code editors
          c:draw_credits_text()
        end)

      end)

    end)  -- (with menu entered)

  end)  -- (with instance)

end)
