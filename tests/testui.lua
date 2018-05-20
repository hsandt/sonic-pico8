require("color")
local picotest = require("picotest")
local ui = require("ui")
local input = require("input")

function test_ui(desc,it)

  local label = ui.label
  local overlay = ui.overlay

  desc('label', function ()


    desc('_init', function ()

      it('should init label with layer', function ()
        local lab = label("great", vector(24, 68), colors.red)
        return lab.text == "great", lab.position == vector(24, 68), lab.colour == colors.red
      end)

    end)

    desc('_tostring', function ()

      it('should return "label(\'[text]\' @ [position] in [colour])"', function ()
        return label("good", vector(22, 62), colors.yellow):_tostring() == "label('good' @ vector(22, 62) in yellow)"
      end)

    end)

    desc('__eq', function ()

      it('should return true for label with same text and position', function ()
        return label("good", vector(22, 62), colors.orange) == label("good", vector(22, 62), colors.orange)
      end)

      it('should return false for label with different text or position', function ()
        return label("good", vector(22, 62), colors.orange) ~= label("bad", vector(22, 62), colors.orange),
          label("good", vector(23, 62), colors.orange) ~= label("good", vector(22, 62), colors.orange),
          label("good", vector(23, 62), colors.orange) ~= label("good", vector(23, 62), colors.peach)
      end)

    end)

  end)

  desc('overlay', function ()

    desc('_init', function ()

      it('should init overlay with layer', function ()
        return overlay(6).layer == 6
      end)

    end)

    desc('_tostring', function ()

      it('should return "overlay(layer [layer])"', function ()
        return overlay(8):_tostring() == "overlay(layer: 8)"
      end)

    end)

    local overlay_instance = overlay(4)

    desc('add_label', function ()

      it('should add a new label', function ()
        overlay_instance:add_label("test", "content", vector(2, 4), colors.red)
        return overlay_instance.labels["test"] == label("content", vector(2, 4), colors.red)
      end)

      it('should replace an existing label', function ()
        -- replace the label added in the previous test
        overlay_instance:add_label("test", "content2", vector(3, 7), colors.white)
        return overlay_instance.labels["test"] == label("content2", vector(3, 7), colors.white)
      end)

    end)

    desc('remove_label', function ()

      it('should remove an existing label', function ()
        -- remove the label added in the previous test
        overlay_instance:remove_label("test")
        return overlay_instance.labels["test"] == nil
      end)

      it('should warn if the label name is not found', function ()
        -- you can also check this by reading terminal output near this method,
        -- with warn active (ugly)
        overlay_instance:remove_label("test")  -- rely on previous removal succeeding
        return overlay_instance.labels["test"] == nil
      end)

    end)

    desc('clear_labels', function ()

      it('should clear any existing label', function ()
        -- remove the label added in the previous test
        overlay_instance:add_label("test", "content", vector(2, 4), colors.red)
        overlay_instance:add_label("test", "content2", vector(3, 7), colors.red)
        overlay_instance:clear_labels()
        return is_empty(overlay_instance.labels)
      end)

    end)

    desc('draw_labels', function ()

      overlay_instance:add_label("test", "content", vector(2, 8), colors.red)
      overlay_instance:add_label("test2", "content2", vector(12, 18), colors.red)

      it('should not crash', function ()
        -- remove the label added in the previous test
        overlay_instance:draw_labels()
        return true
      end)

      clear_table(overlay_instance.labels)

    end)

  end)

  desc('[after toggle_mouse] ui.render_mouse', function ()

    input.toggle_mouse(true)

    it('should draw the cursor (no crash test)', function ()
      ui:render_mouse()
      return true
    end)

    input.toggle_mouse(false)

  end)

end

add(picotest.test_suite, test_ui)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('ui', test_ui)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
