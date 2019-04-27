require("engine/test/bustedhelper")
require("engine/test/unittest_helper")

describe('unittest_helper', function ()

  describe('are_same_with_message', function ()
    it('should return (true, "Expected...") when the values are the same', function ()
      local expected_message = "Expected objects to not be the same (compare_raw_content: false).\nPassed in:\n{[1] = 1, [2] = 2, [3] = 3}\nDid not expect:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({true, expected_message}, {are_same_with_message({1, 2, 3}, {1, 2, 3})})
    end)
    it('should return (false, "Expected...") when the values are not the same', function ()
      local expected_message = "Expected objects to be the same (compare_raw_content: false).\nPassed in:\n{[1] = 1, [2] = 3, [3] = 2}\nExpected:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({false, expected_message}, {are_same_with_message({1, 2, 3}, {1, 3, 2})})
    end)
    it('should return (true, "Expected...") when the values are the same', function ()
      local expected_message = "Expected objects to not be the same (compare_raw_content: true).\nPassed in:\n{[1] = 1, [2] = 2, [3] = 3}\nDid not expect:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({true, expected_message}, {are_same_with_message({1, 2, 3}, {1, 2, 3}, true)})
    end)
    it('should return (false, "Expected...") when the values are not the same', function ()
      local expected_message = "Expected objects to be the same (compare_raw_content: true).\nPassed in:\n{[1] = 1, [2] = 3, [3] = 2}\nExpected:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({false, expected_message}, {are_same_with_message({1, 2, 3}, {1, 3, 2}, true)})
    end)
  end)

end)
