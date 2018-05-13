local picotest = require("picotest")
local input = require("input")

function test_input(desc,it)

  local input_state = input.state

  desc('input.toggle_mouse', function ()
    it('(true) => activate mouse devkit', function ()
      input.toggle_mouse(true)
      return peek(0x5f2d) == 1
    end)
    it('(false) => deactivate mouse devkit', function ()
      input.toggle_mouse(false)
      return peek(0x5f2d) == 0
    end)
  end)

  desc('[after toggle_mouse] input.get_cursor_position', function ()

    input.toggle_mouse(true)

    it('should return the current cursor position (sign test)', function ()
      local cursor_position = input.get_cursor_position()
      -- in headless mode, we cannot predict the mouse position
      -- (it seems to start at (0, 15097) but this may change)
      -- so we just do a simple sign test
      return cursor_position.x >= 0 and cursor_position.y >= 0
    end)

    input.toggle_mouse(false)

  end)

end

add(picotest.test_suite, test_input)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('input', test_input)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
