local picotest = require("picotest")
local ui = require("ui")
local input = require("input")

function test_ui(desc,it)

  local ui_state = ui.state

  desc('[after toggle_mouse] ui.draw_cursor', function ()

    input.toggle_mouse(true)

    it('should draw the cursor (no crash test)', function ()
      ui.draw_cursor()
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
