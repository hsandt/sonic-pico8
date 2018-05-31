require("bustedhelper")
require("engine/core/math")

describe('bustedhelper', function ()

  describe('contains', function ()
    it('should return true when the searched value is contained in the table', function ()
      assert.is_true(contains({1, 2, 3}, 2))
      assert.is_true(contains({"string", vector(2, 4)}, vector(2, 4)))
    end)
    it('should return false when the searched value is not contained in the table', function ()
      assert.is_false(contains({1, 2, 3}, 0))
      assert.is_false(contains({"string", vector(2, 5)}, vector(2, 4)))
    end)
  end)

  describe('contains_with_message', function ()
    it('should return (true, "") when the searched value is contained in the table', function ()
      assert.are_same({true, ""}, {contains_with_message({1, 2, 3}, 2)})
      assert.are_same({true, ""}, {contains_with_message({"string", vector(2, 4)}, vector(2, 4))})
    end)
    it('should return (false, "Expected...") when the searched value is not contained in the table', function ()
      local expected_message = "Expected object to be one of the entries of the sequence.\nPassed in:\n0\nSequence:\n{[1] = 1, [2] = 2, [3] = 3}\n--- Ignore below ---"
      assert.are_same({false, expected_message}, {contains_with_message({1, 2, 3}, 0)})
      local expected_message2 = "Expected object to be one of the entries of the sequence.\nPassed in:\nvector(2, 4)\nSequence:\n".."{[1] = \"string\", [2] = vector(2, 5)}".."\n--- Ignore below ---"
      assert.are_same({false, expected_message2}, {contains_with_message({"string", vector(2, 5)}, vector(2, 4))})
    end)
  end)

  describe('almost_eq_with_message', function ()
    it('should return (true, "") when the searched value is contained in the table', function ()
      assert.are_same({true, ""}, {almost_eq_with_message(2.4, 2.39)})
    end)
    it('should return (false, "Expected...") when the searched value is not contained in the table', function ()
      local expected_message = "Expected objects to be almost equal with eps: 0.001.\nPassed in:\n2.39\nExpected:\n2.4\n--- Ignore below ---"
      assert.are_same({false, expected_message}, {almost_eq_with_message(2.4, 2.39, 0.001)})
    end)
  end)

  describe('get_file_line', function ()
    it('should return "file:line" of the get_file_line call by default', function ()
      assert.are_equal("@tests/testbustedhelper.lua:42", get_file_line())
    end)
    it('should return "file:line" of the function calling get_file_line with extra_level 1', function ()
      local function inside()
        assert.are_equal("@tests/testbustedhelper.lua:48", get_file_line(1))
      end
      inside()  -- line 48
    end)
    it('should return "file:line" of the function calling the function calling get_file_line with extra_level 1', function ()
      local function outside()
        local function inside()
          assert.are_equal("@tests/testbustedhelper.lua:56", get_file_line(1))
          assert.are_equal("@tests/testbustedhelper.lua:58", get_file_line(2))
        end
        inside()  -- line 56
      end
      outside()  -- line 58
    end)
  end)

  describe('print_at_line', function ()

    local print_stub

    setup(function ()
      print_stub = stub(_G, "print")  -- native print
    end)

    teardown(function ()
      print_stub:revert()
    end)

    after_each(function ()
      print_stub:clear()
    end)

    it('should print the current file:line with a message', function ()
      print_at_line("text")
      assert.spy(print_stub).was_called(1)
      assert.spy(print_stub).was_called_with("@tests/testbustedhelper.lua:79: text")
    end)

  end)

end)
