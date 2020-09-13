require("engine/test/bustedhelper")
local credits = require("menu/credits")

local ui = require("engine/ui/ui")

local menu = require("menu/menu")

describe('credits', function ()

  describe('(with instance)', function ()

    local fake_app = {}
    local c

    setup(function ()
      stub(menu, "show_items")
    end)

    teardown(function ()
      menu.show_items:revert()
    end)

    before_each(function ()
      c = credits()
      c.app = fake_app
    end)

    after_each(function ()
      menu.show_items:clear()
    end)

    describe('on_enter', function ()

      it('should create text menu with app', function ()
        c:on_enter()

        assert.are_equal(fake_app, c.menu.app)
        assert.are_same({alignments.horizontal_center, colors.white}, {c.menu.alignment, c.menu.text_color})
      end)

      it('should show text menu', function ()
        c:on_enter()

        assert.spy(menu.show_items).was_called(1)
        assert.spy(menu.show_items).was_called_with(match.ref(c.menu), match.ref(credits.items))
      end)

    end)

    describe('(with menu entered)', function ()

      before_each(function ()
        c:on_enter()
      end)

      describe('update', function ()

        setup(function ()
          stub(menu, "update")
        end)

        teardown(function ()
          menu.update:revert()
        end)

        it('should update menu', function ()
          c:update()

          assert.spy(menu.update).was_called(1)
          assert.spy(menu.update).was_called_with(match.ref(c.menu))
        end)

      end)

      describe('render', function ()

        setup(function ()
          stub(credits, "draw_credits_text")
          -- stub menu.draw completely to avoid altering the count of ui.print_centered calls
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

        it('should draw menu', function ()
          c:render()

          assert.spy(menu.draw).was_called(1)
          -- no need to check where exactly it is printed
        end)

      end)

      describe('draw_credits_text', function ()

        setup(function ()
          stub(ui, "print_centered")
        end)

        teardown(function ()
          ui.print_centered:revert()
        end)

        after_each(function ()
          ui.print_centered:clear()
        end)

        it('should print some author and copyright text centered, in white', function ()
          c:draw_credits_text()

          assert.spy(ui.print_centered).was_called(3)
          -- no need to check what exactly is printed
        end)

      end)

    end)  -- (with menu entered)

  end)  -- (with instance)

end)
