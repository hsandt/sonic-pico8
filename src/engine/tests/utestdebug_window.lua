require("engine/test/bustedhelper")
local debug_window = require("engine/debug/debug_window")
local wtk = require("engine/wtk/pico8wtk")

describe('debug_window', function ()

  after_each(function ()
    debug_window:init()
  end)

  describe('init', function ()

    it('should initialize the gui root, invisible', function ()
      assert.is_not_nil(debug_window.gui)
      assert.is_false(debug_window.gui.visible)
    end)

  end)

  describe('show', function ()

    it('should make the gui root visible', function ()
      debug_window.gui.visible = false  -- in case the default changes
      debug_window:show()
      assert.is_true(debug_window.gui.visible)
    end)

  end)

  describe('hide', function ()

    it('should make the gui root invisible', function ()
      debug_window.gui.visible = true
      debug_window:hide()
      assert.is_false(debug_window.gui.visible)
    end)

  end)

  describe('update', function ()

    it('should call gui.update', function ()
      local update_stub = stub(debug_window.gui, "update")
      debug_window:update()
      assert.spy(update_stub).was_called(1)
      assert.spy(update_stub).was_called_with(match.ref(debug_window.gui))
    end)

  end)

  describe('render_window', function ()

    local draw_stub

    setup(function ()
      draw_stub = stub(debug_window.gui, "draw")
    end)

    teardown(function ()
      draw_stub:revert()
    end)

    it('should reset camera and call gui.draw', function ()
      debug_window:render()
      assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
      assert.spy(draw_stub).was_called(1)
      assert.spy(draw_stub).was_called_with(match.ref(debug_window.gui))
    end)

  end)

  describe('add_label', function ()

    local add_child_stub

    setup(function ()
      add_child_stub = stub(debug_window.gui, "add_child")
    end)

    teardown(function ()
      add_child_stub:revert()
    end)


    it('should call gui.add_child, passing a label(text, color) at position (x, y)', function ()
      debug_window:add_label("hello", 5, 12, 45)
      assert.spy(add_child_stub).was_called(1)
      local label = wtk.label.new("hello", 5)  -- will be matched by table content
      assert.spy(add_child_stub).was_called_with(match.ref(debug_window.gui), label, 12, 45)
    end)

  end)

end)
