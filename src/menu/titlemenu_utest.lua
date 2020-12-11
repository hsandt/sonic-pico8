require("test/bustedhelper_titlemenu")
require("resources/visual_titlemenu_addon")

local titlemenu = require("menu/titlemenu")

local text_helper = require("engine/ui/text_helper")

local picosonic_app = require("application/picosonic_app_titlemenu")
local menu = require("menu/menu")
local visual = require("resources/visual_common")

describe('titlemenu', function ()

  describe('(with instance)', function ()

    local tm

    setup(function ()
      stub(menu, "show_items")
    end)

    teardown(function ()
      menu.show_items:revert()
    end)

    before_each(function ()
      local app = picosonic_app()
      tm = titlemenu()
      -- no need to register gamestate properly, just add app member to pass tests
      tm.app = app
    end)

    after_each(function ()
      menu.show_items:clear()
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

      it('should call start_coroutine_method on opening_sequence_async', function ()
        tm:on_enter()

        local s = assert.spy(picosonic_app.start_coroutine)
        s.was_called(1)
        s.was_called_with(match.ref(tm.app), titlemenu.opening_sequence_async, match.ref(tm))
      end)

    end)

    describe('show_menu', function ()

      it('should create text menu with app', function ()
        tm:show_menu()

        assert.is_not_nil(tm.menu)
        assert.are_equal(tm.app, tm.menu.app)
        assert.are_same({alignments.left, colors.white}, {tm.menu.alignment, tm.menu.text_color})
        assert.are_equal(visual.sprite_data_t.menu_cursor_shoe, tm.menu.left_cursor_sprite_data)
        assert.are_equal(7, tm.menu.left_cursor_half_width)
      end)

      it('should show text menu', function ()
        tm:show_menu()

        assert.spy(menu.show_items).was_called(1)
        assert.spy(menu.show_items).was_called_with(match.ref(tm.menu), match.ref(titlemenu.items))
      end)

    end)

    describe('on_exit', function ()

      it('should clear menu reference', function ()
        tm.menu = {"dummy"}

        tm:on_exit()

        assert.is_nil(tm.menu)
      end)

    end)

    describe('update', function ()

      setup(function ()
        stub(menu, "update")
      end)

      teardown(function ()
        menu.update:revert()
      end)

      it('should not try to update menu if nil', function ()
        tm:update()

        assert.spy(menu.update).was_not_called()
      end)

      describe('(with menu shown)', function ()

        before_each(function ()
          tm:show_menu()
        end)

        it('should update menu', function ()
          tm:update()

          assert.spy(menu.update).was_called(1)
          assert.spy(menu.update).was_called_with(match.ref(tm.menu))
        end)

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

      it('should not try to render menu if nil', function ()
        tm:render()

        assert.spy(menu.draw).was_not_called()
      end)

      describe('(with menu shown)', function ()

        before_each(function ()
          tm:show_menu()
        end)

        it('should draw menu', function ()
          tm:render()

          assert.spy(menu.draw).was_called(1)
          -- no need to check where exactly it is printed
        end)

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

  end)  -- (with instance)

end)
