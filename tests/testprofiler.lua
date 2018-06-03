require("bustedhelper")
local profiler = require("engine/debug/profiler")

describe('profiler', function ()

  setup(function ()
    pico8.memory_usage = 152
    profiler.gui.visible = false
  end)

  describe('get_stat_function', function ()

    it('should return a function that returns a stat name padded', function ()
      local mem_stat_function = profiler.get_stat_function(1)
      assert.are_equal("memory     152", mem_stat_function())
    end)

  end)

  describe('init_window', function ()

    setup(function ()
      profiler:init_window()
    end)

    teardown(function ()
      profiler.initialized = false
      clear_table(profiler.gui.children)
    end)

    it('should initialize the profiler with stat labels and correct callbacks', function ()
      assert.is_true(profiler.initialized)
      assert.is_not_nil(profiler.gui)
      assert.are_equal(6, #profiler.gui.children)  -- size of stats_info
      assert.are_equal("function", type(profiler.gui.children[1].text))
      assert.are_equal("memory     152", profiler.gui.children[1].text())
    end)

  end)

  describe('update_window', function ()

    local update_stub

    setup(function ()
      update_stub = stub(profiler.gui, "update")
    end)

    teardown(function ()
      update_stub:revert()
    end)

    it('should call gui.update', function ()
      profiler:update_window()
      assert.spy(update_stub).was_called(1)
      assert.spy(update_stub).was_called_with(profiler.gui)
    end)

  end)

  describe('show', function ()

    setup(function ()
      profiler:show()
    end)

    teardown(function ()
      profiler:hide()
      clear_table(profiler.gui.children)
      profiler.initialized = false
    end)

    it('should initialize the profiler if not already', function ()
      assert.is_true(profiler.initialized)
    end)

    it('should make the gui visible', function ()
      assert.is_true(profiler.gui.visible)
    end)

    describe('render_window', function ()

      local draw_stub

      setup(function ()
        draw_stub = stub(profiler.gui, "draw")
      end)

      teardown(function ()
        draw_stub:revert()
      end)

      it('should call gui.draw', function ()
        profiler:render_window()
        assert.spy(draw_stub).was_called(1)
        assert.spy(draw_stub).was_called_with(profiler.gui)
      end)

    end)

  end)

  describe('hide', function ()

    setup(function ()
      profiler:show()
    end)

    teardown(function ()
      profiler.gui.visible = false
      clear_table(profiler.gui.children)
      profiler.initialized = false
    end)

    it('should make the gui invisible', function ()
      profiler:hide()
      assert.is_false(profiler.gui.visible)
    end)

  end)

end)
