require("engine/test/bustedhelper")
local menu = require("menu/menu")

local flow = require("engine/application/flow")
local gameapp = require("engine/application/gameapp")
local input = require("engine/input/input")
local sprite_data = require("engine/render/sprite_data")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")
local visual = require("resources/visual")

describe('menu', function ()

  local fake_app = gameapp(60)

  describe('init', function ()

    it('should set passed items, alignment and color, and set selection index to 0', function ()
      local m = menu(fake_app, 5, alignments.left, colors.red, vector(12, 2))

      assert.are_equal(fake_app, m.app)
      assert.are_same({5, alignments.left, colors.red, vector(12, 2), {}, false, 0, 0, 0},
        {m.items_count_per_page, m.alignment, m.text_color, m.prev_page_arrow_offset, m.items, m.active, m.selection_index, m.anim_time, m.prev_page_arrow_extra_y})
    end)

    it('should set default arrow offset to (0, 0)', function ()
      local m = menu(fake_app, 5, alignments.left, colors.red)

      assert.are_equal(vector(0, 0), m.prev_page_arrow_offset)
    end)

  end)

  describe('(with instance, 2 items per page)', function ()

    local callback1 = function () end
    local callback2 = spy.new(function () end)
    local callback3 = spy.new(function () end)
    local callback4 = spy.new(function () end)

    local mock_items = {
      menu_item("in-game", callback1),
      menu_item("credits", callback2, callback3)
    }

    local mock_items_multipage = {
      menu_item("in-game", callback1),
      menu_item("credits", callback2, callback3),
      menu_item("extra1", callback4),
      menu_item("extra2", callback4),
      menu_item("extra3", callback4)
    }

    local m

    before_each(function ()
      m = menu(fake_app, 2, alignments.left, colors.red, vector(20, -4))
    end)

    describe('show_items', function ()

      setup(function ()
        spy.on(menu, "try_select_callback")
        end)

      teardown(function ()
        menu.try_select_callback:revert()
        end)

      after_each(function ()
        menu.try_select_callback:clear()
      end)

      it('should error with empty items', function ()
        assert.has_error(function ()
            m.show_items({})
        end)
      end)

      it('should activate the menu', function ()
        m:show_items(mock_items)

        assert.is_true(m.active)
      end)

      it('should fill items with deep copy of items', function ()
        m:show_items(mock_items)

        assert.are_same(mock_items, m.items)
        assert.are_not_equal(mock_items, m.items)
        assert.is_false(rawequal(mock_items[1], m.items[1]))
        assert.is_false(rawequal(mock_items[2], m.items[2]))
      end)

      it('should set selection index to 1', function ()
        m:show_items(mock_items)

        assert.are_equal(1, m.selection_index)
      end)

      it('should call try_select_callback', function ()
        m:show_items(mock_items)

        local s = assert.spy(menu.try_select_callback)
        s.was_called(1)
        s.was_called_with(match.ref(m), 1)
      end)

      it('should initialize animation state', function ()
        m:show_items(mock_items)

        assert.are_same({0, 0}, {m.anim_time, m.prev_page_arrow_extra_y})
      end)

    end)

    describe('clear', function ()

      before_each(function ()
        -- rely on show_items being correct
        m:show_items(mock_items)
      end)

      it('should deactivate the menu', function ()
        m:clear(mock_items)

        assert.is_false(m.active)
      end)

      it('should empty items', function ()
        m:clear(mock_items)

        assert.are_equal(0, #m.items)
      end)

      it('should clear the selection index', function ()
        m:clear(mock_items)

        assert.are_equal(0, m.selection_index)
      end)

    end)

    describe('update', function ()

      setup(function ()
        stub(menu, "select_previous")
        stub(menu, "select_next")
        stub(menu, "confirm_selection")
      end)

      teardown(function ()
        menu.select_previous:revert()
        menu.select_next:revert()
        menu.confirm_selection:revert()
      end)

      after_each(function ()
        input.players_btn_states[0][button_ids.up] = btn_states.released
        input.players_btn_states[0][button_ids.down] = btn_states.released
        input.players_btn_states[0][button_ids.x] = btn_states.released

        menu.select_previous:clear()
        menu.select_next:clear()
        menu.confirm_selection:clear()
      end)

      describe('(inactive)', function ()

        it('(when various inputs are down) should still do nothing', function ()
          input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
          input.players_btn_states[0][button_ids.down] = btn_states.just_pressed
          input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

          m:update()

          assert.spy(menu.select_previous).was_not_called()
          assert.spy(menu.select_next).was_not_called()
          assert.spy(menu.confirm_selection).was_not_called()
        end)

        it('should not update anim time nor offset', function ()
          m:update()

          assert.are_same({0, 0}, {m.anim_time, m.prev_page_arrow_extra_y})
        end)

      end)

      describe('(active)', function ()

        before_each(function ()
          m:show_items(mock_items)
        end)

        it('(when input up is just pressed) it should move cursor up', function ()
          input.players_btn_states[0][button_ids.up] = btn_states.just_pressed

          m:update()

          local s = assert.spy(menu.select_previous)
          s.was_called(1)
          s.was_called_with(match.ref(m))
        end)

        it('(when input down is just pressed) it should move cursor down', function ()
          input.players_btn_states[0][button_ids.down] = btn_states.just_pressed

          m:update()

          local s = assert.spy(menu.select_next)
          s.was_called(1)
          s.was_called_with(match.ref(m))
        end)

        it('(when input o is just pressed) it should confirm selection', function ()
          input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

          m:update()

          local s = assert.spy(menu.confirm_selection)
          s.was_called(1)
          s.was_called_with(match.ref(m))
        end)

        it('should increase anim_time', function ()
          m:update()

          assert.are_equal(1/60, m.anim_time)
          -- m.prev_page_arrow_extra_y}
        end)

        it('should increase anim_time and loop around period', function ()
          -- no vertical arrow graphics in pico-sonic, and no paginated menu for now anyway,
          -- so replaced visual_data.menu_arrow_anim_period with some number 2
          m.anim_time = 2 - 1/120

          m:update()

          -- lua used in busted finds decimal error at 17th decimal (PICO-8 fixed point is OK)
          assert.is_true(almost_eq_with_message(1/120, m.anim_time, 1e-10))
        end)

        it('should set arrow extra y to 0 on first half', function ()
          -- impossible situation, but simple enough to check that extra y is reset
          m.anim_time = 0
          m.prev_page_arrow_extra_y = 1

          m:update()

          assert.are_equal(0, m.prev_page_arrow_extra_y)
        end)

        it('should set arrow extra y to 1 on second half', function ()
          -- impossible situation, but simple enough to check that extra y is reset
          -- no vertical arrow graphics in pico-sonic, and no paginated menu for now anyway,
          -- so replaced visual_data.menu_arrow_anim_period with some number 2
          m.anim_time = 2 / 2
          m.prev_page_arrow_extra_y = 0

          m:update()

          assert.are_equal(-1, m.prev_page_arrow_extra_y)
        end)

      end)  -- (active)

    end)  -- update

    describe('(showing 2 items)', function ()

      before_each(function ()
        m:show_items(mock_items)
      end)

      describe('try_select_callback', function ()

        it('should not call any select callback if there is none at passed item index', function ()
          local s = assert.has_no_errors(function ()
            m:try_select_callback(1)
          end)
        end)

        it('should call select callback if there is one at passed item index', function ()
          m:try_select_callback(2)

          local s = assert.spy(callback3)
          s.was_called(1)
          s.was_called_with(match.ref(fake_app))
        end)

      end)

      describe('confirm_selection', function ()

        setup(function ()
          stub(menu, "on_confirm_selection")
        end)

        teardown(function ()
          menu.on_confirm_selection:revert()
        end)

        after_each(function ()
          menu.on_confirm_selection:clear()
        end)

        it('should deactivate the menu (keeping items)', function ()
          m:confirm_selection()

          assert.is_false(m.active)
        end)

        it('should call on_confirm_selection', function ()

          m:confirm_selection()

          local s = assert.spy(menu.on_confirm_selection)
          s.was_called(1)
          s.was_called_with(match.ref(m))
        end)

      end)

      describe('(when selection index is 1)', function ()

        describe('(stubbing on_selection_changed)', function ()

          setup(function ()
            stub(menu, "try_select_callback")
            stub(menu, "on_selection_changed")
          end)

          teardown(function ()
            menu.try_select_callback:revert()
            menu.on_selection_changed:revert()
          end)

          -- before_each and not after_each as show_items in before_each above
          --   calls try_select_callback once already
          -- (on_selection_changed is not called there, so could be in after_each)
          before_each(function ()
            menu.try_select_callback:clear()
            menu.on_selection_changed:clear()
          end)

          describe('change_selection', function ()

            it('should set selection if new index', function ()
              m:change_selection(2)
              assert.are_equal(2, m.selection_index)
            end)

            it('should not call try_select_callback if no index change', function ()
              m:change_selection(1)

              local s = assert.spy(menu.try_select_callback)
              s.was_not_called()
            end)

            it('should call try_select_callback if index change', function ()
              m:change_selection(2)

              local s = assert.spy(menu.try_select_callback)
              s.was_called(1)
              s.was_called_with(match.ref(m), 2)
            end)

            it('should not call on_selection_changed if no index change', function ()
              m:change_selection(1)

              local s = assert.spy(menu.on_selection_changed)
              s.was_not_called()
            end)

            it('should call on_selection_changed if index change', function ()
              m:change_selection(2)

              local s = assert.spy(menu.on_selection_changed)
              s.was_called(1)
              s.was_called_with(match.ref(m))
            end)

          end)

          describe('(spying change_selection)', function ()

            setup(function ()
              spy.on(menu, "change_selection")
            end)

            teardown(function ()
              menu.change_selection:revert()
            end)

            after_each(function ()
              menu.change_selection:clear()
            end)

            describe('select_previous', function ()

              it('should not call change_selection due to clamping', function ()
                m:select_previous()

                local s = assert.spy(menu.change_selection)
                s.was_not_called()
              end)

            end)

            describe('select_next', function ()

              it('should call change_selection', function ()
                m:select_next()

                local s = assert.spy(menu.change_selection)
                s.was_called(1)
                s.was_called_with(match.ref(m), 2)
              end)

            end)

          end)

        end)

      end)

      describe('(when selection index is max (2))', function ()

        before_each(function ()
          m.selection_index = 2
        end)

        describe('(stubbing on_selection_changed)', function ()

          setup(function ()
            stub(menu, "on_selection_changed")
          end)

          teardown(function ()
            menu.on_selection_changed:revert()
          end)

          -- before_each and not after_each as show_items in before_each above
          --   calls on_selection_changed once already
          before_each(function ()
            menu.on_selection_changed:clear()
          end)

          describe('(spying change_selection)', function ()

            setup(function ()
              spy.on(menu, "change_selection")
            end)

            teardown(function ()
              menu.change_selection:revert()
            end)

            after_each(function ()
              menu.change_selection:clear()
            end)

            describe('select_previous', function ()

              it('should call change_selection', function ()
                m:select_previous()

                local s = assert.spy(menu.change_selection)
                s.was_called(1)
                s.was_called_with(match.ref(m), 1)
              end)

            end)

            describe('select_next', function ()

              it('should not call change_selection due to clamping', function ()
                m:select_next()

                local s = assert.spy(menu.change_selection)
                s.was_not_called(1)
              end)

            end)

          end)

        end)

        describe('confirm_selection', function ()

          after_each(function ()
            callback2:clear()
          end)

          it('should call confirm callback', function ()
            m:confirm_selection()

            local s = assert.spy(callback2)
            s.was_called(1)
            s.was_called_with(match.ref(fake_app))
          end)

        end)

      end)

    end)  -- (showing 2 items)

    describe('draw', function ()

      setup(function ()
        stub(ui, "print_aligned")
        stub(sprite_data, "render")
      end)

      teardown(function ()
        ui.print_aligned:revert()
        sprite_data.render:revert()
      end)

      after_each(function ()
        ui.print_aligned:clear()
        sprite_data.render:clear()
      end)

      describe('(inactive)', function ()

        it('it should do nothing', function ()
          m:draw(77, 99)

          assert.spy(ui.print_aligned).was_not_called()
        end)

      end)

      describe('(showing 2 items, below max items per page)', function ()

        before_each(function ()
          m:show_items(mock_items)
        end)

        it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection prepended by ">" for left alignment', function ()
          m.selection_index = 2  -- credits

          m:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          -- non-selected item is offset to the right
          s.was_called_with("in-game", 68, 48, alignments.left, colors.red)
          s.was_called_with("> credits", 60, 54, alignments.left, colors.red)
        end)

        it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection surrounded by "> <" for horizontally centered alignment', function ()
          m.alignment = alignments.horizontal_center
          m.selection_index = 2  -- credits

          m:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          s.was_called_with("in-game", 60, 48, alignments.horizontal_center, colors.red)
          s.was_called_with("> credits <", 60, 54, alignments.horizontal_center, colors.red)
        end)

        it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection surrounded by "> <" for centered alignment', function ()
          m.alignment = alignments.center
          m.selection_index = 2  -- credits

          m:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          s.was_called_with("in-game", 60, 48, alignments.center, colors.red)
          s.was_called_with("> credits <", 60, 54, alignments.center, colors.red)
        end)

        it('should not print any previous/next page arrow', function ()
          m:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_not_called()
        end)

      end)  -- (showing 2 items, below max items per page)

      describe('(showing 5 items, so 2 pages + 1 item)', function ()

        before_each(function ()
          m:show_items(mock_items_multipage)
        end)

        it('(selection falls on page 1) should print item labels for page 1', function ()
          m.selection_index = 2  -- credits

          m:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          -- non-selected item is offset to the right
          s.was_called_with("in-game", 68, 48, alignments.left, colors.red)
          s.was_called_with("> credits", 60, 54, alignments.left, colors.red)
        end)

        it('(selection falls on page 2) should print item labels for page 2', function ()
          m.selection_index = 3  -- extra1

          m:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          s.was_called_with("> extra1", 60, 48, alignments.left, colors.red)
          -- non-selected item is offset to the right
          s.was_called_with("extra2", 68, 54, alignments.left, colors.red)
        end)

        it('(selection falls on page 3) should print item labels for page 2', function ()
          m.selection_index = 5  -- extra3

          m:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(1)
          s.was_called_with("> extra3", 60, 48, alignments.left, colors.red)
        end)

        -- no vertical arrow graphics in pico-sonic, and no paginated menu for now anyway,
        -- so not drawing page arrows right now
        --[[

        it('(selection falls on page 1/3) should draw next page arrow (previous arrow y-flipped)', function ()
          m.selection_index = 1

          m:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_called(1)
          -- 60 + offset 20 = 80
          -- 48 + 2 lines * char height 6 - offset -4 + 1 = 66
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 65), false, true)
        end)

        it('(selection falls on page 2/3) should draw previous and next page arrow', function ()
          m.selection_index = 4

          m:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_called(2)
          -- 60 + offset 20 = 80
          -- 48 - margin 2 - offset 4 = 42
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 42))
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 65), false, true)
        end)

        it('(selection falls on page 3/3) should draw previous page arrow', function ()
          m.selection_index = 5  -- extra3

          m:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_called(1)
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 42))
        end)

        it('(selection falls on page 2/3 + arrow anim y = -1) should draw previous and next page arrow with extra offset', function ()
          m.selection_index = 4
          -- impossible if anim_time ratio is not >= 0.5, but enough to test
          m.prev_page_arrow_extra_y = -1

          m:draw(60, 48)


          assert.spy(sprite_data.render).was_called(2)
          -- x: 60 + offset 20 = 80
          -- y: 48 - margin 2 - offset 4 + anim offset -1 = 41
          assert.spy(sprite_data.render).was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 41))
          -- y: 48 - margin 2 - offset 4 + anim offset -1 = 41
          -- y: 48 + 2 lines * char height 6 - offset -4 - anim offset -1 + 1 = 66
          assert.spy(sprite_data.render).was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 66), false, true)
        end)

        --]]

      end)  -- (showing 5 items, so 2 pages + 1 item)

    end)  -- draw

  end)  -- (with instance)

end)
