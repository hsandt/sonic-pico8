require("engine/test/bustedhelper")
require("engine/core/math")

describe('bustedhelper', function ()

  describe('get_file_line', function ()
    it('should return "file:line" of the get_file_line call by default', function ()
      assert.are_equal("@src/engine/tests/utestbustedhelper.lua:8", get_file_line())  -- line 8
    end)
    it('should return "file:line" of the function calling get_file_line with extra_level 1', function ()
      local function inside()
        assert.are_equal("@src/engine/tests/utestbustedhelper.lua:14", get_file_line(1))
      end
      inside()  -- line 14
    end)
    it('should return "file:line" of the function calling the function calling get_file_line with extra_level 1', function ()
      local function outside()
        local function inside()
          assert.are_equal("@src/engine/tests/utestbustedhelper.lua:22", get_file_line(1))
          assert.are_equal("@src/engine/tests/utestbustedhelper.lua:24", get_file_line(2))
        end
        inside()  -- line 22
      end
      outside()  -- line 24
    end)
  end)

  describe('print_at_line', function ()

    local native_print_stub

    setup(function ()
      native_print_stub = stub(_G, "print")  -- native print
    end)

    teardown(function ()
      native_print_stub:revert()
    end)

    after_each(function ()
      native_print_stub:clear()
    end)

    it('should print the current file:line with a message', function ()
      print_at_line("text") -- line 45
      assert.spy(native_print_stub).was_called(1)
      assert.spy(native_print_stub).was_called_with("@src/engine/tests/utestbustedhelper.lua:45: text")
    end)

  end)

end)
