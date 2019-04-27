require("engine/test/bustedhelper")
helper = require("engine/core/helper")
math = require("engine/core/math")  -- just to test stringify and are_same

describe('enum', function ()
  it('should return a table containing enum variants with the names passed as a sequence, values starting from 1', function ()
    assert.are_same({
        left = 1,
        right = 2,
        up = 3,
        down = 4
      }, enum {"left", "right", "up", "down"})
  end)
end)

describe('get_members', function ()
  it('should return module members from their names as multiple values', function ()
    local module = {
      a = 1,
      b = 2,
      [3] = function () end
    }
    assert.are_same({module.a, module.b, module[3]},
      {get_members(module, "a", "b", 3)})
  end)
end)

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

  local comparable_mt_sum = {
    __eq = function (lhs, rhs)
      -- a flexible check that allows different member values to have the table considered equal in the end
      return lhs.a + lhs.b == rhs.a + rhs.b
    end
  }
  local comparable_mt_offset = {
    __eq = function (lhs, rhs)
      -- a contrived check that makes sure __eq is used by returning true when it should be false in raw content
      return lhs.a == rhs.a - 1
    end
  }

  local comparable_struct1 = {a = 1, b = 2}
  local comparable_struct2 = {a = 1, b = 2}
  local comparable_struct3 = {a = 2, b = 1}
  local comparable_struct4 = {a = 1}
  local comparable_struct5 = {a = 1}
  local comparable_struct6 = {a = 2}

  setmetatable(comparable_struct1, comparable_mt_sum)
  setmetatable(comparable_struct2, comparable_mt_sum)
  setmetatable(comparable_struct3, comparable_mt_sum)
  setmetatable(comparable_struct4, comparable_mt_offset)
  setmetatable(comparable_struct5, comparable_mt_offset)
  setmetatable(comparable_struct6, comparable_mt_offset)

  -- bugfix history:
  -- _ the non-table and comparable_struct tests below have been added, as I was exceptionally covering
  --   the utest files themselves and saw that the metatables were not used at all; so I fixed are_same itself
  --   to check __eq on the metatable instead of the table

  it('return true if both elements are not table, but equal', function ()
    assert.is_true(are_same(2, 2))
  end)
  it('return false if both elements are not table, and not equal', function ()
    assert.is_false(are_same(2, 3))
  end)

  it('return true if both tables define __eq that returns true, and not comparing raw content', function ()
    assert.is_true(are_same(comparable_struct1, comparable_struct2))
    assert.is_true(are_same(comparable_struct1, comparable_struct3))
    assert.is_true(are_same(comparable_struct4, comparable_struct6))
  end)
  it('return true if both tables define __eq that returns false, and not comparing raw content', function ()
    assert.is_false(are_same(comparable_struct4, comparable_struct5))
  end)

  it('return false if both tables define __eq that returns true, but comparing different raw content', function ()
    assert.is_false(are_same(comparable_struct1, comparable_struct3, true))
    assert.is_false(are_same(comparable_struct4, comparable_struct6, true))
  end)

  it('return true if both tables define __eq that returns false, but comparing same raw content', function ()
    assert.is_true(are_same(comparable_struct4, comparable_struct5, true))
  end)

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
  it('return false if both tables are sequences with the same elements by value at deep level', function ()
    assert.is_true(are_same({1, 2, {}}, {1, 2, {}}))
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
  it('return true if both tables have the same keys and values by value', function ()
    assert.is_true(are_same({a = "str", t = {}}, {a = "str", t = {}}))
  end)
  it('return false if both tables have the same values but a key differs by reference', function ()
    assert.is_false(are_same({[{20}] = 10}, {[{20}] = 10}))
  end)
  it('return true if both tables have the same key refs and value contents by defined equality', function ()
    assert.is_true(are_same({a = "str", t = {e = vector(5, 8)}}, {a = "str", t = {e = vector(5, 8)}}, true))
  end)
  it('return false if we don\'t compare_raw_content and some values have the same content but differ by type', function ()
    assert.is_false(are_same({x = 5, y = 8}, vector(5, 8)))
  end)
  it('return false if we don\'t compare_raw_content and some values have the same content but differ by type (deep)', function ()
    assert.is_false(are_same({a = "str", t = {e = {x = 5, y = 8}}}, {a = "str", t = {e = vector(5, 8)}}))
  end)
  it('return true if we compare_raw_content and some values have the same content, even if they differ by type (deep)', function ()
    assert.is_true(are_same({x = 5, y = 8}, vector(5, 8), true))
  end)
  it('return true if we compare_raw_content and some values have the same content, even if they differ by type (deep)', function ()
    assert.is_true(are_same({{x = 1, y = 2}, t = {e = {x = 5, y = 8}}}, {vector(1, 2), t = {e = vector(5, 8)}}, true))
  end)
  it('return false if we compare_raw_content and some values have the same content, but they differ by type at a deep level', function ()
    assert.is_false(are_same({{x = 1, y = 2}, t = {e = {x = 5, y = 8}}}, {vector(1, 2), t = {e = vector(5, 8)}}, true, true))
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

describe('invert_table', function ()
  it('should return a table with reversed keys and values', function ()
    assert.are_same({[41] = "a", foo = 1}, invert_table({a = 41, [1] = "foo"}))
  end)
end)

describe('string_tonum', function ()
  it('"100" => 100', function ()
    assert.are_equal(100, string_tonum("100"))
  end)
  -- unlike tonum, this one works for both pico8 and native Lua
  it('"-25.25" => -25.25', function ()
    assert.are_equal(-25.25, string_tonum("-25.25"))
  end)
  it('"304.25" => 304.25', function ()
    assert.are_equal(304.25, string_tonum(304.25))
  end)
  it('"-25.25" => -25.25', function ()
    assert.are_equal(-25.25, string_tonum(-25.25))
  end)
  it('"0x0000.2fa4" => 0x0000.2fa4', function ()
    assert.are_equal(0x0000.2fa4, string_tonum("0x0000.2fa4"))
  end)
  it('"-0x0000.2fa4" => -0x0000.2fa4', function ()
    assert.are_equal(-0x0000.2fa4, string_tonum("-0x0000.2fa4"))
  end)
  it('"-abc" => error (minus sign instead of hyphen-minus)', function ()
    assert.has_error(function ()
      string_tonum("-abc")
    end,
    "could not parse absolute part of number: '-abc'")
  end)
  it('"−5" => error (minus sign instead of hyphen-minus)', function ()
    assert.has_error(function ()
      string_tonum("−5")
    end,
    "could not parse number: '−5'")
  end)
  it('"abc" => error (minus sign instead of hyphen-minus)', function ()
    assert.has_error(function ()
      string_tonum("abc")
    end,
    "could not parse number: 'abc'")
  end)
  it('nil => error', function ()
    assert.has_error(function ()
      string_tonum(nil)
    end,
    "bad argument #1 to 'sub' (string expected, got nil)")
  end)
  it('true => error', function ()
    assert.has_error(function ()
      string_tonum(true)
    end,
    "bad argument #1 to 'sub' (string expected, got boolean)")
  end)
  it('{} => error', function ()
    assert.has_error(function ()
      string_tonum({})
    end,
    "bad argument #1 to 'sub' (string expected, got table)")
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

describe('wwrap', function ()
  it('+ wwrap("hello", 5) => "hello"', function ()
    assert.are_equal("hello", wwrap("hello", 5))
  end)
  it('+ wwrap("hello world", 5) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello world", 5))
  end)
  it('+ wwrap("hello world", 10) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello world", 10))
  end)
  it('wwrap("hello world", 11) => "hello world"', function ()
    assert.are_equal("hello world", wwrap("hello world", 11))
  end)
  it('+ wwrap("toolongfromthestart", 5) => "toolongfromthestart" (we can\'t warp at all, give up)', function ()
    assert.are_equal("toolongfromthestart", wwrap("toolongfromthestart", 5))
  end)
  it('wwrap("toolongfromthestart this is okay", 5) => "toolongfromthestart\nthis\nis\nokay" (we can\'t warp at all, give up)', function ()
    assert.are_equal("toolongfromthestart\nthis\nis\nokay", wwrap("toolongfromthestart this is okay", 5))
  end)
  it('wwrap("hello\nworld", 5) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello\nworld", 5))
  end)
  it('wwrap("hello world\nhow are you today?", 8) => "hello\nworld\nhow are\nyou\ntoday?"', function ()
    assert.are_equal("hello\nworld\nhow are\nyou\ntoday?", wwrap("hello world\nhow are you today?", 8))
  end)
  it('wwrap("short\ntoolongfromthestart\nshort again", 8) => "short\ntoolongfromthestart\nshort\nagain"', function ()
    assert.are_equal("short\ntoolongfromthestart\nshort\nagain", wwrap("short\ntoolongfromthestart\nshort again", 8))
  end)
end)

describe('strspl', function ()
  it('strspl("", " ") => {""}', function ()
    assert.are_same({}, strspl("", " "))
  end)
  it('strspl("hello", " ") => {"hello"}', function ()
    assert.are_same({"hello"}, strspl("hello", " "))
  end)
  it('strspl("hello world", " ") => {"hello", "world"}', function ()
    assert.are_same({"hello", "world"}, strspl("hello world", " "))
  end)
  it('strspl("hello world", "l") => {"he", "", "o wor", "d"} (multiple separators leave empty strings)', function ()
    assert.are_same({"he", "", "o wor", "d"}, strspl("hello world", "l"))
  end)
  it('strspl("hello\nworld", "\n") => {"hello", "world"}', function ()
    assert.are_same({"hello", "world"}, strspl("hello\nworld", "\n"))
  end)
  it('strspl("hello world", "lo") => {"hello world"} (multicharacter not supported)', function ()
    assert.are_same({"hello world"}, strspl("hello world", "lo"))
  end)
  it('strspl("|a||b", "|", false) => {"", a", "", "b"}', function ()
    assert.are_same({"", "a", "", "b"}, strspl("|a||b", "|", false))
  end)
  it('strspl("|a||b", "|", true) => {"a", "b"}', function ()
    assert.are_same({"a", "b"}, strspl("|a||b", "|", true))
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
