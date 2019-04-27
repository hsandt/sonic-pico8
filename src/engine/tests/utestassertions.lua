require("engine/test/bustedhelper")
require("engine/core/math")
require("engine/test/assertions")

describe('assertions', function ()

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
    it('should return (true, "Expected...") when the searched value is contained in the table', function ()
      local expected_message = "Expected object not to be one of the entries of the sequence.\nPassed in:\n2\nSequence:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({true, expected_message}, {contains_with_message({1, 2, 3}, 2)})
      local expected_message2 = "Expected object not to be one of the entries of the sequence.\nPassed in:\nvector(2, 4)\nSequence:\n".."{[1] = \"string\", [2] = vector(2, 4)}"..""
      assert.are_same({true, expected_message2}, {contains_with_message({"string", vector(2, 4)}, vector(2, 4))})
    end)
    it('should return (false, "Expected...") when the searched value is not contained in the table', function ()
      local expected_message = "Expected object to be one of the entries of the sequence.\nPassed in:\n0\nSequence:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({false, expected_message}, {contains_with_message({1, 2, 3}, 0)})
      local expected_message2 = "Expected object to be one of the entries of the sequence.\nPassed in:\nvector(2, 4)\nSequence:\n".."{[1] = \"string\", [2] = vector(2, 5)}"..""
      assert.are_same({false, expected_message2}, {contains_with_message({"string", vector(2, 5)}, vector(2, 4))})
    end)
  end)

  describe('eq_with_message', function ()
    it('should return (true, "Expected...") when the passed value is equal to the expected one', function ()
      local expected_message = "Expected objects to not be equal.\nPassed in:\n2.4\nDid not expect:\n2.4"
      assert.are_same({true, expected_message}, {eq_with_message(2.4, 2.4)})
    end)
    it('should return (false, "Expected...") when the passed value is not equal to the expected one', function ()
      local expected_message = "Expected objects to be equal.\nPassed in:\n2.3\nExpected:\n2.4"
      assert.are_same({false, expected_message}, {eq_with_message(2.4, 2.3)})
    end)
  end)

  describe('almost_eq_with_message', function ()
    it('should return (true, "Expected...") when the passed value is almost equal to the expected one', function ()
      local expected_message = "Expected objects to not be almost equal with eps: 0.01.\nPassed in:\n2.39\nDid not expect:\n2.4"
      assert.are_same({true, expected_message}, {almost_eq_with_message(2.4, 2.39, 0.01)})
    end)
    it('should return (false, "Expected...") when the passed value is not almost equal to the expected one', function ()
      local expected_message = "Expected objects to be almost equal with eps: 0.001.\nPassed in:\n2.39\nExpected:\n2.4"
      assert.are_same({false, expected_message}, {almost_eq_with_message(2.4, 2.39, 0.001)})
    end)
  end)

end)
