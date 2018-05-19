local picotest = require("picotest")
require("debug")

function test_debug(desc,it)

  desc('log functions', function ()

    it('log should not crash', function ()
      log("message1")
      log("message2", "flow")
      return true
    end)

    it('warn should not crash', function ()
      warn("message1")
      warn("message2", "flow")
      return true
    end)

    it('err should not crash', function ()
      err("message1")
      err("message2", "flow")
      return true
    end)

  end)

  desc('dump', function ()

    -- basic types
    it('nil => "[nil]"', function ()
      return dump(nil) == "[nil]"
    end)
    it('"string" => ""string""', function ()
      return dump("string") == "\"string\""
    end)
    it('true => "true"', function ()
      return dump(true) == "true"
    end)
    it('false => "false"', function ()
      return dump(false) == "false"
    end)
    it('56 => "56"', function ()
      return dump(56) == "56"
    end)
    it('56.2 => "56.2"', function ()
      return dump(56.2) == "56.2"
    end)

    -- as key

    it('"string" => "string"', function ()
      return dump("string", true) == "string"
    end)
    it('true => "[true]"', function ()
      return dump(true, true) == "[true]"
    end)
    it('56.2 => "[56.2]"', function ()
      return dump(56.2, true) == "[56.2]"
    end)

    -- tables

    it('{1 nil "string"} => "{[1] = 1 [3] = "string"}"', function ()
      return dump({1, nil, "string"}) == "{[1] = 1, [3] = \"string\"}"
    end)

    it('{[7] = 5 string = "other"} => "{[7] = 5 string = "other"}', function ()
      return dump({[7] = 5, string = "other"}) == "{[7] = 5, string = \"other\"}"
    end)

    it('{5 "text" string = "other"} => "{[1] = 5 [2] = "text" string = "other"}', function ()
      return dump({5, "text", string = "other"}) == "{[1] = 5, [2] = \"text\", string = \"other\"}"
    end)

    it('{...} => "{[1] = 2 mytable = {[1] = 1 [2] = 3 key = "value"}}', function ()
      return dump({2, mytable = {1, 3, key = "value"}}) == "{[1] = 2, mytable = {[1] = 1, [2] = 3, key = \"value\"}}"
    end)

    it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = 11}', function ()
      return dump({[{1, 3, key = "value"}] = 11}) == "{[{[1] = 1, [2] = 3, key = \"value\"}] = 11}"
    end)

    it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = {[1] = true [2] = false}}', function ()
      return dump({[{1, 3, key = "value"}] = {true, false}}) == "{[{[1] = 1, [2] = 3, key = \"value\"}] = {[1] = true, [2] = false}}"
    end)

    -- infinite recursion prevention
    it('{} => [table]', function ()
      return dump({}, false, 2) == "[table]",
        dump({}, true, 2) == "[table]"
    end)
    it('{...} => "{{[1] = 1 [2] = [table] [3] = "rest"} = {idem}', function ()
      return dump({[{1, {2, {3, {4}}}, "rest"}] = {1, {2, {3, {4}}}, "rest"}}) == "{[{[1] = 1, [2] = [table], [3] = \"rest\"}] = {[1] = 1, [2] = [table], [3] = \"rest\"}}"
    end)

    -- function

    it('function => "[function]"', function ()
      local f = function ()
      end
      return dump(f, false) == "[function]",
        dump(f, true) == "[function]"
    end)

  end)

end

add(picotest.test_suite, test_debug)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('debug', test_debug)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
