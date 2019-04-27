require("engine/test/bustedhelper")
require("engine/render/color")
local ui = require("engine/ui/ui")
local input = require("engine/input/input")
local sprite_data = require("engine/render/sprite_data")

local label = ui.label
local overlay = ui.overlay

describe('ui', function ()

  describe('label', function ()

    describe('_init', function ()

      it('should init label with layer', function ()
        local lab = label("great", vector(24, 68), colors.red)
        assert.are_same({"great", vector(24, 68), colors.red}, {lab.text, lab.position, lab.colour})
      end)

    end)

    describe('_tostring', function ()

      it('should return "label(\'[text]\' @ [position] in [colour])"', function ()
        assert.are_equal("label('good' @ vector(22, 62) in yellow)", label("good", vector(22, 62), colors.yellow):_tostring())
      end)

    end)

  end)

  describe('overlay', function ()

    describe('_init', function ()

      it('should init overlay with layer', function ()
        assert.are_equal(6, overlay(6).layer)
      end)

    end)

    describe('_tostring', function ()

      it('should return "overlay(layer [layer])"', function ()
        assert.are_equal("overlay(layer: 8)", overlay(8):_tostring())
      end)

    end)

    describe('(overlay instance)', function ()

      local overlay_instance

      setup(function ()
        overlay_instance = overlay(4)
      end)

      describe('(no labels)', function ()

        teardown(function ()
          clear_table(overlay_instance.labels)
        end)

        describe('add_label', function ()

          local warn_stub

          setup(function ()
            warn_stub = stub(_G, "warn")
          end)

          teardown(function ()
            warn_stub:revert()
          end)

          after_each(function ()
            warn_stub:clear()
          end)

          it('should add a new label', function ()
            overlay_instance:add_label("test", "content", vector(2, 4), colors.red)
            assert.are_equal(label("content", vector(2, 4), colors.red), overlay_instance.labels["test"])
          end)

          it('should add a new black label with warning if no colour is passed', function ()
            overlay_instance:add_label("test", "content", vector(2, 4))
            assert.spy(warn_stub).was_called(1)
            assert.spy(warn_stub).was_called_with('overlay:add_label no colour passed, will default to black (0)', 'ui')
            assert.are_equal(label("content", vector(2, 4), colors.black), overlay_instance.labels["test"])
          end)

        end)

      end)

      describe('(label "mock" and "mock2" added)', function ()

        before_each(function ()
          overlay_instance:add_label("mock", "mock content", vector(1, 1), colors.blue)
          overlay_instance:add_label("mock2", "mock content 2", vector(2, 2), colors.dark_purple)
        end)

        after_each(function ()
          clear_table(overlay_instance.labels)
        end)

        describe('add_label', function ()

          it('should replace an existing label', function ()
            overlay_instance:add_label("mock", "mock content 2", vector(3, 7), colors.white)
            assert.are_equal(label("mock content 2", vector(3, 7), colors.white), overlay_instance.labels["mock"])
          end)

        end)

        describe('remove_label', function ()

          local warn_stub

          setup(function ()
            warn_stub = stub(_G, "warn")
          end)

          teardown(function ()
            warn_stub:revert()
          end)

          after_each(function ()
            warn_stub:clear()
          end)

          it('should remove an existing label', function ()
            overlay_instance:remove_label("mock")
            assert.is_nil(overlay_instance.labels["mock"])
          end)

          it('should warn if the label name is not found', function ()
            overlay_instance:remove_label("test")
            assert.spy(warn_stub).was_called(1)
            assert.spy(warn_stub).was_called_with('overlay:remove_label: could not find label with name: \'test\'', 'ui')
            assert.is_nil(overlay_instance.labels["test"])
          end)

        end)

        describe('clear_labels', function ()

          it('should clear any existing label', function ()
            overlay_instance:clear_labels()
            return is_empty(overlay_instance.labels)
          end)

        end)

        describe('draw_labels', function ()

          local api_print_stub

          setup(function ()
            api_print_stub = stub(api, "print")
          end)

          teardown(function ()
            api_print_stub:revert()
          end)

          after_each(function ()
            api_print_stub:clear()
          end)

          it('should call print', function ()
            overlay_instance:draw_labels()
            assert.spy(api_print_stub).was_called(2)
            assert.spy(api_print_stub).was_called_with("mock content", 1, 1, colors.blue)
            assert.spy(api_print_stub).was_called_with("mock content 2", 2, 2, colors.dark_purple)
          end)

        end)

      end)  -- (label "mock" and "mock2" added)

    end)  -- (overlay instance)

  end)  -- overlay

  describe('render_mouse', function ()

    describe('(without cursor sprite data)', function ()

      describe('(mouse off)', function ()

        it('should not error (by testing for nil)', function ()
          assert.has_no_errors(function () ui:render_mouse() end)
        end)

      end)

      describe('(mouse on at (12, 48))', function ()

        setup(function ()
          input:toggle_mouse(true)
          pico8.mousepos.x = 12
          pico8.mousepos.y = 48
        end)

        teardown(function ()
          input:toggle_mouse(false)
        end)

        it('should not error (by testing for nil)', function ()
          assert.has_no_errors(function () ui:render_mouse() end)
        end)

      end)

    end)  -- (without cursor sprite data)

    describe('(with cursor sprite data)', function ()

      local cursor_render_stub

      setup(function ()
        ui:set_cursor_sprite_data(sprite_data(sprite_id_location(1, 0)))
        cursor_render_stub = stub(ui.cursor_sprite_data, "render")
      end)

      teardown(function ()
        cursor_render_stub:revert()
      end)

      after_each(function ()
        cursor_render_stub:clear()
      end)

      describe('(mouse off)', function ()

        it('should not call cursor sprite render', function ()
          ui:render_mouse()
          assert.spy(cursor_render_stub).was_not_called()
        end)

      end)

      describe('(mouse shown at (12, 48))', function ()

        setup(function ()
          input:toggle_mouse(true)
          pico8.mousepos.x = 12
          pico8.mousepos.y = 48
        end)

        teardown(function ()
          input:toggle_mouse(false)
        end)

        -- bugfix history:
        -- .. i forgot to use match.ref, which was ok until struct_eq uses are_same with compare_raw_content: true
        --    which causes infinite recursion when trying to compare a spied method on a struct (as it contains a ref to itself)
        it('should call cursor sprite render at (12, 48)', function ()
          ui:render_mouse()
          assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
          assert.spy(cursor_render_stub).was_called(1)
          assert.spy(cursor_render_stub).was_called_with(match.ref(ui.cursor_sprite_data), vector(12, 48))
        end)

      end)

    end)  -- (with cursor sprite data)

  end)  -- ui.render_mouse

end)
