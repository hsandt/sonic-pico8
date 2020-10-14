require("engine/test/bustedhelper")
local titlemenu = require("menu/titlemenu")

local text_helper = require("engine/ui/text_helper")

local menu = require("menu/menu")

local visual = require("resources/visual_common")  -- just to use titlemenu add-on
require("resources/visual_titlemenu_addon")

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
        assert.are_same({alignments.left, colors.white}, {tm.menu.alignment, tm.menu.text_color})
        assert.are_equal(visual.sprite_data_t.menu_cursor, tm.menu.left_cursor_sprite_data)
        assert.are_equal(7, tm.menu.left_cursor_half_width)
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
          stub(titlemenu, "draw_background")
          stub(titlemenu, "draw_title")
          -- stub menu.draw completely to avoid altering the count of text_helper.print_centered calls
          stub(menu, "draw")
        end)

        teardown(function ()
          titlemenu.draw_background:revert()
          titlemenu.draw_title:revert()
          menu.draw:revert()
        end)

        after_each(function ()
          titlemenu.draw_background:clear()
          titlemenu.draw_title:clear()
          menu.draw:clear()
        end)

        it('should draw background', function ()
          tm:render()

          assert.spy(titlemenu.draw_background).was_called(1)
          assert.spy(titlemenu.draw_background).was_called_with(match.ref(tm))
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

        -- we don't mind what intermediate render methods are called,
        -- we just stub PICO-8 API in case it causes side effects
        --  (but it will only change things like draw color which
        --  should be reset before any test on draw color itself anyway)

        setup(function ()
          stub(_G, "spr")
          stub(_G, "pset")
        end)

        teardown(function ()
          spr:revert()
          pset:revert()
        end)

        it('should not crash', function ()
          tm:draw_title()
        end)

      end)

    end)  -- (with menu entered)

  end)  -- (with instance)

end)
