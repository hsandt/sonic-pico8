require("engine/test/bustedhelper")
local titlemenu = require("menu/titlemenu")

local text_helper = require("engine/ui/text_helper")

local menu = require("menu/menu")

describe('titlemenu', function ()

  describe('(with instance)', function ()

    local fake_app = {}
    local tm

    setup(function ()
      stub(menu, "show_items")
    end)

    teardown(function ()
      menu.show_items:revert()
    end)

    before_each(function ()
      tm = titlemenu()
      tm.app = fake_app
    end)

    after_each(function ()
      menu.show_items:clear()
    end)

    describe('on_enter', function ()

      it('should create text menu with app', function ()
        tm:on_enter()

        assert.are_equal(fake_app, tm.menu.app)
        assert.are_same({alignments.horizontal_center, colors.white}, {tm.menu.alignment, tm.menu.text_color})
      end)

      it('should show text menu', function ()
        tm:on_enter()

        assert.spy(menu.show_items).was_called(1)
        assert.spy(menu.show_items).was_called_with(match.ref(tm.menu), match.ref(titlemenu.items))
      end)

    end)

    describe('(with menu entered)', function ()

      before_each(function ()
        tm:on_enter()
      end)

      describe('update', function ()

        setup(function ()
          stub(menu, "update")
        end)

        teardown(function ()
          menu.update:revert()
        end)

        it('should update menu', function ()
          tm:update()

          assert.spy(menu.update).was_called(1)
          assert.spy(menu.update).was_called_with(match.ref(tm.menu))
        end)

      end)

      describe('render', function ()

        setup(function ()
          stub(titlemenu, "draw_title")
          -- stub menu.draw completely to avoid altering the count of text_helper.print_centered calls
          stub(menu, "draw")
        end)

        teardown(function ()
          titlemenu.draw_title:revert()
          menu.draw:revert()
        end)

        after_each(function ()
          titlemenu.draw_title:clear()
          menu.draw:clear()
        end)

        it('should draw title', function ()
          tm:render()

          assert.spy(titlemenu.draw_title).was_called(1)
          assert.spy(titlemenu.draw_title).was_called_with(match.ref(tm))
        end)

        it('should draw menu', function ()
          tm:render()

          assert.spy(menu.draw).was_called(1)
          -- no need to check where exactly it is printed
        end)

      end)

      describe('draw_title', function ()

        setup(function ()
          stub(text_helper, "print_centered")
        end)

        teardown(function ()
          text_helper.print_centered:revert()
        end)

        after_each(function ()
          text_helper.print_centered:clear()
        end)

        it('should print "pico-sonic by leyn" centered, in white', function ()
          tm:draw_title()

          assert.spy(text_helper.print_centered).was_called(2)
          -- no need to check what exactly is printed
        end)

      end)

    end)  -- (with menu entered)

  end)  -- (with instance)

end)
