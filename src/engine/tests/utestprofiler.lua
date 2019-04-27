require("engine/test/bustedhelper")
local profiler = require("engine/debug/profiler")

describe('profiler', function ()

  setup(function ()
    pico8.memory_usage = 152
  end)

  describe('get_stat_function', function ()

    it('should return a function that returns a stat name padded', function ()
      local mem_stat_function = profiler.get_stat_function(1)
      assert.are_equal("memory     152", mem_stat_function())
    end)

  end)

  describe('window', function ()

    it('should initialize the profiler, invisible, with stat labels and correct callbacks', function ()
      local add_label_global_stub = stub(profiler.window, "add_label")
      profiler.window:init()  -- was already called, but recall it to spy this time
      assert.spy(add_label_global_stub).was_called(6)
      assert.spy(add_label_global_stub).was_called_with(match.ref(profiler.window), profiler.stat_functions[1], colors.light_gray, 1, 1)
      assert.spy(add_label_global_stub).was_called_with(match.ref(profiler.window), profiler.stat_functions[2], colors.light_gray, 1, 7)
      assert.spy(add_label_global_stub).was_called_with(match.ref(profiler.window), profiler.stat_functions[3], colors.light_gray, 1, 13)
      assert.spy(add_label_global_stub).was_called_with(match.ref(profiler.window), profiler.stat_functions[4], colors.light_gray, 1, 19)
      assert.spy(add_label_global_stub).was_called_with(match.ref(profiler.window), profiler.stat_functions[5], colors.light_gray, 1, 25)
      assert.spy(add_label_global_stub).was_called_with(match.ref(profiler.window), profiler.stat_functions[6], colors.light_gray, 1, 31)
    end)

  end)

end)
