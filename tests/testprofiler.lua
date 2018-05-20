local picotest = require("picotest")
local profiler = require("profiler")

function test_profiler(desc,it)

  desc('profiler.get_stat_function', function ()

    it('should return a function that returns a stat name padded', function ()
      local mem_stat_function = profiler.get_stat_function(1)
      -- hard to test for current stat value, but we can test the padded stat name
      -- and at least the beginning of the stat value number which should be stable enough
      -- ex: memory     152
      return sub(mem_stat_function(), 1, 14) == "memory     "..sub(stat(0), 1, 3)
    end)

  end)

  desc('profiler.show', function ()

    profiler:show()

    it('should initialize the profiler if not already', function ()
      return profiler.initialized
    end)

    it('should make the gui visible', function ()
      return profiler.gui.visible
    end)

  end)

  desc('profiler.hide', function ()

    profiler:hide()

    it('should make the gui invisible', function ()
      return not profiler.gui.visible
    end)

  end)

  profiler.initialized = false
  clear_table(profiler.gui.children)

  desc('profiler.init_window', function ()

    profiler:init_window()

    it('should initialize the profiler with stat labels and correct callbacks', function ()
      return profiler.initialized,
      profiler.gui ~= nil,
      profiler.gui ~= nil and #profiler.gui.children == 6,  -- size of stats_info
      profiler.gui ~= nil and #profiler.gui.children == 6 and
        type(profiler.gui.children[1].text) == "function",
      profiler.gui ~= nil and #profiler.gui.children == 6 and
        type(profiler.gui.children[1].text) == "function" and
        sub(profiler.gui.children[1].text(), 1, 14) == "memory     "..sub(stat(0), 1, 3)
    end)

    profiler.initialized = false
    clear_table(profiler.gui.children)

  end)

  desc('profiler.update_window', function ()

    it('should not crash"', function ()
      profiler:update_window()
      return true
    end)

  end)

  desc('profiler.render_window', function ()

    it('should not crash"', function ()
      profiler:render_window()
      return true
    end)

  end)

end

add(picotest.test_suite, test_profiler)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('profiler', test_profiler)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
