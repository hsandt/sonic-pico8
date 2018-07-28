require("bustedhelper")
helper = require("engine/core/helper")
math = require("engine/core/math")  -- just to test stringify

describe('is_empty', function ()
  it('return true if the table is empty', function ()
    assert.is_true(is_empty({}))
  end)
  it('return false if the sequence is not empty', function ()
    assert.is_false(is_empty({2, "ah"}))
  end)
  it('return false if the table has only non-sequence entries', function ()
    assert.is_false(is_empty({a = "str"}))
  end)
  it('return false if the table has a mix of entries', function ()
    assert.is_false(is_empty({4, 5, d = "dummy"}))
  end)
end)

describe('are_same', function ()

  local single_t = {}

  local comparable_mt = {
    __eq = function (lhs, rhs)
      return lhs.a == rhs.a and lhs.b == rhs.b
    end
  }
  local comparable_struct1 = {a = 1, b = 2}
  local comparable_struct2 = {a = 1, b = 2}
  setmetatable(comparable_struct1, comparable_mt)
  setmetatable(comparable_struct2, comparable_mt)  -- actually, only one is enough

  it('return true both tables are empty', function ()
    assert.is_true(are_same({}, {}))
  end)
  it('return true if both tables are sequences with the same elements in order', function ()
    assert.is_true(are_same({false, "ah"}, {false, "ah"}))
  end)
  it('return true if both tables are sequences with the same elements by ref in order', function ()
    assert.is_true(are_same({2, single_t}, {2, single_t}))
  end)
  it('return true if both tables are former sequences with a hole with the same elements in order', function ()
    assert.is_true(are_same({2, nil, "ah"}, {2, nil, "ah"}))
  end)
  it('return true if both tables have the same keys and values', function ()
    assert.is_true(are_same({a = "str", b = "at"}, {b = "at", a = "str"}))
  end)
  it('return true if both tables have the same keys and values by reference', function ()
    assert.is_true(are_same({a = "str", b = single_t, c = nil}, {b = single_t, c = nil, a = "str"}))
  end)
  it('return true if both tables have the same keys and values', function ()
    assert.is_true(are_same({a = false, b = "at"}, {b = "at", a = false}))
  end)
  it('return true if both tables have the same keys and values by custom equality', function ()
    assert.is_true(are_same({a = "str", b = comparable_struct1}, {b = comparable_struct2, a = "str"}))
  end)
  it('return true if both tables have the same keys and values, even if their metatables differ', function ()
    local t1 = {}
    setmetatable(t1, {})
    local t2 = {}
    assert.is_true(are_same(t1, t2))
  end)
  it('return false if both tables are sequences but an element is missing on the first', function ()
    assert.is_false(are_same({1, 2}, {1, 2, 3}))
  end)
  it('return false if both tables are sequences but an element is missing on the second', function ()
    assert.is_false(are_same({1, 2, 3}, {1, 2}))
  end)
  it('return false if both tables are sequences but an element differs', function ()
    assert.is_false(are_same({1, 2, 3}, {1, 2, 4}))
  end)
  it('return false if both tables are sequences but an element differs by reference', function ()
    assert.is_false(are_same({1, 2, {}}, {1, 2, {}}))
  end)
  it('return false if first table has a key the other doesn\'t have', function ()
    assert.is_false(are_same({a = false, b = "at"}, {a = false}))
  end)
  it('return false if second table has a key the other doesn\'t have', function ()
    assert.is_false(are_same({b = "the"}, {c = 54, b = "the"}))
  end)
  it('return false if both tables have the same keys but a value differs', function ()
    assert.is_false(are_same({a = false, b = "at"}, {a = false, b = "the"}))
  end)
  it('return false if both tables have the same keys but a value differs by reference', function ()
    assert.is_false(are_same({a = "str", t = {}}, {a = "str", t = {}}))
  end)
end)

describe('clear_table', function ()
  it('should clear a sequence', function ()
    local t = {1, 5, -5}
    clear_table(t)
    assert.are_equal(0, #t)
  end)
  it('should clear a table', function ()
    local t = {1, 5, a = "b", b = 50.1}
    clear_table(t)
    assert.is_true(is_empty(t))
  end)
end)

describe('unpack', function ()
  it('should unpack a sequence fully by default', function ()
    local function foo(a, b, c)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
    end
    foo(unpack({1, "foo", 20.2}))
  end)
  it('should unpack a sequence from start if from is not passed', function ()
    local function foo(a, b, c, d)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
      assert.are_not_equal(50, d)
    end
    foo(unpack({1, "foo", 20.2, 50}, nil, 3))
  end)
  it('should unpack a sequence to the end if to is not passed', function ()
    local function foo(a, b, c)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
    end
    foo(unpack({45, 1, "foo", 20.2}, 2))
  end)
  it('should unpack a sequence from from to to', function ()
    local function foo(a, b, c, d)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
      assert.are_not_equal(50, d)
    end
    foo(unpack({45, 1, "foo", 20.2, 50}, 2, 4))
  end)
end)

describe('stringify', function ()
  it('nil => "[nil]"', function ()
    assert.are_equal("[nil]", stringify(nil))
  end)
  it('"string" => "string"', function ()
    assert.are_equal("string", stringify("string"))
  end)
  it('true => "true"', function ()
    assert.are_equal("true", stringify(true))
  end)
  it('false => "false"', function ()
    assert.are_equal("false", stringify(false))
  end)
  it('56 => "56"', function ()
    assert.are_equal("56", stringify(56))
  end)
  it('56.2 => "56.2"', function ()
    assert.are_equal("56.2", stringify(56.2))
  end)
  it('vector(2 3) => "vector(2 3)" (_tostring implemented)', function ()
    assert.are_equal("vector(2, 3)", stringify(vector(2, 3)))
  end)
  it('{} => "[table]" (_tostring not implemented)', function ()
    assert.are_equal("[table]", stringify({}))
  end)
  it('function => "[function]"', function ()
    local f = function ()
    end
    assert.are_equal("[function]", stringify(f))
  end)

end)

describe('joinstr_table', function ()
  it('joinstr_table("_" {nil 5 "at" nil}) => "[nil]_5_at"', function ()
    assert.are_equal("[nil]_5_at", joinstr_table("_", {nil, 5, "at", nil}))
  end)
  it('joinstr_table("comma " nil 5 "at" {}) => "[nil]comma 5comma atcomma [table]"', function ()
    assert.are_equal("[nil], 5, at, [table]", joinstr_table(", ", {nil, 5, "at", {}}))
  end)
end)

describe('joinstr', function ()
  it('joinstr("" nil 5 "at" nil) => "[nil]5at"', function ()
    assert.are_equal("[nil]5at", joinstr("", nil, 5, "at", nil))
  end)
  it('joinstr("comma " nil 5 "at" {}) => "[nil]comma 5comma atcomma [table]"', function ()
    assert.are_equal("[nil], 5, at, [table]", joinstr(", ", nil, 5, "at", {}))
  end)
end)

describe('yield_delay (wrapped in set_var_after_delay_async)', function ()
  local test_var
  local coroutine

  local function set_var_after_delay_async(delay)
    yield_delay(delay)
    test_var = 1
  end

  before_each(function ()
    test_var = 0
    coroutine = cocreate(set_var_after_delay_async)
  end)

  it('should start suspended', function ()
    assert.are_equal("suspended", costatus(coroutine))
    assert.are_equal(0, test_var)
  end)

  it('should not stop after 59/60 frames (for a delay of 1s)', function ()
    coresume(coroutine, 1.0)  -- pass delay of 60 frames in 1st call
    for t = 2, 1.0 * fps - 1 do
      coresume(coroutine)  -- further calls don't need arg, it's only used as yield() return value
    end
    assert.are_equal("suspended", costatus(coroutine))
    assert.are_equal(0, test_var)
  end)
  it('should stop after the 60th frame, and continue body execution', function ()
    coresume(coroutine, 1.0)
    for t=2, 1.0 * fps do
      coresume(coroutine)
    end
    assert.are_equal("dead", costatus(coroutine))
    assert.are_equal(1, test_var)
  end)

  it('should not stop after 60/60.6 frames (for a delay of 1.01s)', function ()
    coresume(coroutine, 1.01)  -- pass delay of 60.6 frames in 1st call
    for t=2, 1.0 * fps do
      coresume(coroutine)
    end
    assert.are_equal("suspended", costatus(coroutine))
    assert.are_equal(0, test_var)
  end)
  it('should stop after the 61th frame (ceil of 60.6), and continue body execution', function ()
    coresume(coroutine, 1.01)  -- pass delay of 60.6 frames in 1st call
    for t=2, 1.0 * fps + 1 do
      coresume(coroutine)
    end
    assert.are_equal("dead", costatus(coroutine))
    assert.are_equal(1, test_var)
  end)

end)
