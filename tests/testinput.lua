require("bustedhelper")
local input = require("engine/input/input")

describe('input', function ()

  describe('toggle_mouse', function ()

    describe('(mouse devkit inactive)', function ()

      before_each(function ()
        input.mouse_active = false
        poke(0x5f2d, 0)
      end)

      after_each(function ()
        input.mouse_active = false
        poke(0x5f2d, 0)
      end)

      it('(true) => activate mouse devkit', function ()
        input:toggle_mouse(true)
        assert.are_same({1, true}, {peek(0x5f2d), input.mouse_active})
      end)

      it('(false) => deactivate mouse devkit', function ()
        input:toggle_mouse(false)
        assert.are_same({0, false}, {peek(0x5f2d), input.mouse_active})
      end)

      it('() => toggle to active', function ()
        input:toggle_mouse()
        assert.are_same({1, true}, {peek(0x5f2d), input.mouse_active})
      end)

    end)

    describe('(mouse devkit active)', function ()

      before_each(function ()
        input.mouse_active = true
        poke(0x5f2d, 1)
      end)

      after_each(function ()
        input.mouse_active = false
        poke(0x5f2d, 0)
      end)

      it('(true) => activate mouse devkit', function ()
        input:toggle_mouse(true)
        assert.are_same({1, true}, {peek(0x5f2d), input.mouse_active})
      end)

      it('(false) => deactivate mouse devkit', function ()
        input:toggle_mouse(false)
        assert.are_same({0, false}, {peek(0x5f2d), input.mouse_active})
      end)

      it('() => toggle to inactive', function ()
        input:toggle_mouse()
        assert.are_same({0, false}, {peek(0x5f2d), input.mouse_active})
      end)

    end)

  end)

end)

describe('(mouse toggled)', function ()

  setup(function ()
    input:toggle_mouse(true)
  end)

  teardown(function ()
    input:toggle_mouse(false)
  end)

  describe('get_cursor_position', function ()

    it('should return the current cursor position (sign test)', function ()
      local cursor_position = input.get_cursor_position()
      -- in headless mode, we cannot predict the mouse position
      -- (it seems to start at (0, 15097) but this may change)
      -- so we just do a simple sign test
      assert.is_true(cursor_position.x >= 0)
      assert.is_true(cursor_position.y >= 0)
    end)

  end)

end)
