require("test/bustedhelper_titlemenu")
require("resources/visual_titlemenu_addon")

local titlemenu = require("menu/titlemenu")

local input = require("engine/input/input")
local text_helper = require("engine/ui/text_helper")

local picosonic_app = require("application/picosonic_app_titlemenu")
local menu = require("menu/menu")
local visual = require("resources/visual_common")

describe('titlemenu', function ()

  describe('init', function ()

    it('should initialize members', function ()
      local tm = titlemenu()

      -- a bit complicated to test the generated items, so just test length for items
      assert.are_equal(2, #tm.items)
      -- don't go into details for this one, which is very animation-related
      assert.is_not_nil(tm.title_logo_drawable)
      assert.are_equal(0, tm.frames_before_showing_menu)
      assert.is_false(tm.should_start_attract_mode)
      assert.is_false(tm.is_playing_start_cinematic)
    end)

  end)

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

      it('should call start_coroutine_method on play_opening_music_async', function ()
        tm:on_enter()

        assert.spy(picosonic_app.start_coroutine).was_called(1)
        assert.spy(picosonic_app.start_coroutine).was_called_with(match.ref(tm.app), titlemenu.play_opening_music_async, match.ref(tm))
      end)

      it('should initialize frames_before_showing_menu for countdown and reset should_start_attract_mode and is_playing_start_cinematic', function ()
        tm:on_enter()

        assert.are_equal(96, tm.frames_before_showing_menu)
        assert.is_false(tm.should_start_attract_mode)
        assert.is_false(tm.is_playing_start_cinematic)
      end)

      it('should initialize title_logo_drawable.position', function ()
        tm:on_enter()

        assert.are_equal(vector(8, 16), tm.title_logo_drawable.position)
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
        assert.spy(menu.show_items).was_called_with(match.ref(tm.menu), match.ref(tm.items))
      end)

    end)

    describe('on_exit', function ()

      setup(function ()
        stub(picosonic_app, "stop_all_coroutines")
      end)

      teardown(function ()
        picosonic_app.stop_all_coroutines:revert()
      end)

      after_each(function ()
        picosonic_app.stop_all_coroutines:clear()
      end)

      it('should clear menu reference', function ()
        tm.menu = {"dummy"}

        tm:on_exit()

        assert.is_nil(tm.menu)
      end)

      it('should call stop_all_coroutines', function ()
        tm:on_exit()

        assert.spy(picosonic_app.stop_all_coroutines).was_called(1)
        assert.spy(picosonic_app.stop_all_coroutines).was_called_with(match.ref(tm.app))
      end)

    end)

    describe('update', function ()

      setup(function ()
        stub(menu, "update")
        stub(titlemenu, "show_menu")
        stub(titlemenu, "start_attract_mode")
      end)

      teardown(function ()
        menu.update:revert()
        titlemenu.show_menu:revert()
        titlemenu.start_attract_mode:revert()
      end)

      after_each(function ()
        menu.update:clear()
        titlemenu.show_menu:clear()
        titlemenu.start_attract_mode:clear()
      end)

      it('(no menu) should not try to update menu', function ()
        tm:update()

        assert.spy(menu.update).was_not_called()
      end)

      describe('(simulating input)', function ()

        after_each(function ()
          -- reset all inputs
          input:init()
        end)

        it('(button O pressed) should set frames_before_showing_menu to 0 and immediately show menu', function ()
          tm.frames_before_showing_menu = 99
          input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

          tm:update()

          assert.are_equal(0, tm.frames_before_showing_menu)

          assert.spy(titlemenu.show_menu).was_called(1)
          assert.spy(titlemenu.show_menu).was_called_with(match.ref(tm))
        end)

      end)

      it('(button O not pressed, frames_before_showing_menu > 1) should decrement frames_before_showing_menu, but not show menu yet', function ()
        tm.frames_before_showing_menu = 2

        tm:update()

        assert.are_equal(1, tm.frames_before_showing_menu)
        assert.spy(titlemenu.show_menu).was_not_called(1)
      end)

      it('(button O not pressed, frames_before_showing_menu <= 1) should decrement frames_before_showing_menu to <=0 and show menu', function ()
        tm.frames_before_showing_menu = 1

        tm:update()

        assert.are_equal(0, tm.frames_before_showing_menu)

        assert.spy(titlemenu.show_menu).was_called(1)
        assert.spy(titlemenu.show_menu).was_called_with(match.ref(tm))
      end)

      it('(button O not pressed, frames_before_showing_menu <= 1 BUT is_playing_start_cinematic) should NOT decrement frames_before_showing_menu to <=0 and NOT show menu', function ()
        tm.frames_before_showing_menu = 1
        tm.is_playing_start_cinematic = true

        tm:update()

        assert.are_equal(1, tm.frames_before_showing_menu)

        assert.spy(titlemenu.show_menu).was_not_called()
      end)

      it('(no menu) should not try to update menu', function ()
        tm:update()

        assert.spy(menu.update).was_not_called()
      end)

      describe('(with menu shown)', function ()

        before_each(function ()
          -- dummy menu
          tm.menu = menu(tm.app--[[, 2]], alignments.left, 3, colors.white--[[skip prev_page_arrow_offset]], visual.sprite_data_t.menu_cursor_shoe, 7)
        end)

        it('should update menu', function ()
          tm:update()

          assert.spy(menu.update).was_called(1)
          assert.spy(menu.update).was_called_with(match.ref(tm.menu))
        end)

        it('(should_start_attract_mode: false) should not start attract mode', function ()
          tm.should_start_attract_mode = false

          tm:update()

          assert.spy(titlemenu.start_attract_mode).was_not_called()
        end)

        it('(should_start_attract_mode: true) should start attract mode', function ()
          tm.should_start_attract_mode = true

          tm:update()

          assert.spy(titlemenu.start_attract_mode).was_called(1)
          assert.spy(titlemenu.start_attract_mode).was_called_with(match.ref(tm))
        end)

      end)

    end)

    describe('start_attract_mode', function ()

      setup(function ()
        stub(_G, "load")
      end)

      teardown(function ()
        load:revert()
      end)

      after_each(function ()
        load:clear()
      end)

      it('should load attract mode cartridge', function ()
        tm:start_attract_mode()

        assert.spy(load).was_called(1)
        assert.spy(load).was_called_with('picosonic_attract_mode')
      end)

    end)

    describe('render', function ()

      setup(function ()
        stub(titlemenu, "draw_background")
        stub(titlemenu, "draw_title")
        stub(titlemenu, "draw_version")
        -- stub menu.draw completely to avoid altering the count of text_helper.print_centered calls
        stub(menu, "draw")
      end)

      teardown(function ()
        titlemenu.draw_background:revert()
        titlemenu.draw_title:revert()
        titlemenu.draw_version:revert()
        menu.draw:revert()
      end)

      after_each(function ()
        titlemenu.draw_background:clear()
        titlemenu.draw_title:clear()
        titlemenu.draw_version:clear()
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

      it('should draw version', function ()
        tm:render()

        assert.spy(titlemenu.draw_version).was_called(1)
        assert.spy(titlemenu.draw_version).was_called_with(match.ref(tm))
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
