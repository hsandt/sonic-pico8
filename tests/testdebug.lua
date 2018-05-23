require("test")
local debug = require("engine/debug/debug")

describe('log functions', function ()
  local printh_stub

  setup(function ()
    debug.active_categories.flow = true
    printh_stub = stub(_G, "printh")
  end)

  teardown(function ()
    printh_stub:revert()
  end)

  after_each(function ()
    printh_stub:clear()
  end)

  describe('(debug level set to log)', function ()

    setup(function ()
      debug.current_level = debug.level.log
    end)

    teardown(function ()
      debug.current_level = debug.level.none
    end)

    describe('(default category active)', function ()
      local old_active_categories_default = debug.active_categories.default

      setup(function ()
        debug.active_categories.default = true
      end)

      teardown(function ()
        debug.active_categories.default = old_active_categories_default
      end)

      describe('log', function ()

        it('should print with no argument (default)', function ()
          log("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] message1")
        end)

        it('should print with explicit category: default', function ()
          log("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] message1")
        end)

      end)

      describe('warn', function ()

        it('should print with no argument (default)', function ()
          warn("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] warning: message1")
        end)

        it('should print with explicit category: default', function ()
          warn("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] warning: message1")
        end)

      end)

      describe('err', function ()

        it('should print with no argument (default)', function ()
          err("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] error: message1")
        end)

        it('should print with explicit category: default', function ()
          err("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] error: message1")
        end)

      end)

    end)

    describe('(flow category active)', function ()
      local old_active_categories_flow = debug.active_categories.flow

      setup(function ()
        debug.active_categories.flow = true
      end)

      teardown(function ()
        debug.active_categories.flow = old_active_categories_flow
      end)

      describe('log', function ()

        it('should print with explicit category: flow', function ()
          log("message1", "flow")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[flow] message1")
        end)

      end)

      describe('warn', function ()

        it('should print with explicit category: flow', function ()
          warn("message1", "flow")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[flow] warning: message1")
        end)

      end)

      describe('err', function ()

        it('should print with explicit category: flow', function ()
          err("message1", "flow")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[flow] error: message1")
        end)

      end)

    end)

    describe('(default category inactive)', function ()
      local old_active_categories_default = debug.active_categories.default

      setup(function ()
        debug.active_categories.default = false
      end)

      teardown(function ()
        debug.active_categories.default = old_active_categories_default
      end)

      describe('log', function ()

        it('should not print with no argument (default)', function ()
          log("message1")
          assert.spy(printh_stub).was.not_called()
        end)

        it('should not print with explicit category: default', function ()
          log("message1")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

      describe('warn', function ()

        it('should not print with no argument (default)', function ()
          warn("message1")
          assert.spy(printh_stub).was.not_called()
        end)

        it('should not print with explicit category: default', function ()
          warn("message1")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

      describe('err', function ()

        it('should not print with no argument (default)', function ()
          err("message1")
          assert.spy(printh_stub).was.not_called()
        end)

        it('should not print with explicit category: default', function ()
          err("message1")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

    end)

    describe('(flow category inactive)', function ()
      local old_active_categories_flow = debug.active_categories.flow

      setup(function ()
        debug.active_categories.flow = false
      end)

      teardown(function ()
        debug.active_categories.flow = old_active_categories_flow
      end)

      describe('log', function ()

        it('should not print with explicit category: flow', function ()
          log("message1", "flow")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

      describe('warn', function ()

        it('should not print with explicit category: flow', function ()
          warn("message1", "flow")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

      describe('err', function ()

        it('should not print with explicit category: flow', function ()
          err("message1", "flow")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

    end)

  end)

  describe('(debug level set to warning)', function ()

    setup(function ()
      debug.current_level = debug.level.warning
    end)

    teardown(function ()
      debug.current_level = debug.level.none
    end)

    describe('log', function ()

      it('should never print', function ()
        log("message1")
        log("message1", "default")
        log("message1", "flow")
        assert.spy(printh_stub).was.not_called()
      end)

    end)

    describe('(default category active)', function ()
      local old_active_categories_default = debug.active_categories.default

      setup(function ()
        debug.active_categories.default = true
      end)

      teardown(function ()
        debug.active_categories.default = old_active_categories_default
      end)

      describe('warn', function ()

        it('should print with no argument (default)', function ()
          warn("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] warning: message1")
        end)

        it('should print with explicit category: default', function ()
          warn("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] warning: message1")
        end)

      end)

      describe('err', function ()

        it('should print with no argument (default)', function ()
          err("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] error: message1")
        end)

        it('should print with explicit category: default', function ()
          err("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] error: message1")
        end)

      end)

    end)

    describe('(flow category active)', function ()
      local old_active_categories_flow = debug.active_categories.flow

      setup(function ()
        debug.active_categories.flow = true
      end)

      teardown(function ()
        debug.active_categories.flow = old_active_categories_flow
      end)

      describe('warn', function ()

        it('should print with explicit category: flow', function ()
          warn("message1", "flow")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[flow] warning: message1")
        end)

      end)

      describe('err', function ()

        it('should print with explicit category: flow', function ()
          err("message1", "flow")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[flow] error: message1")
        end)

      end)

    end)

    describe('(default category inactive)', function ()
      local old_active_categories_default = debug.active_categories.default

      setup(function ()
        debug.active_categories.default = false
      end)

      teardown(function ()
        debug.active_categories.default = old_active_categories_default
      end)

      describe('warn', function ()

        it('should not print with no argument (default)', function ()
          warn("message1")
          assert.spy(printh_stub).was.not_called()
        end)

        it('should not print with explicit category: default', function ()
          warn("message1")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

      describe('err', function ()

        it('should not print with no argument (default)', function ()
          err("message1")
          assert.spy(printh_stub).was.not_called()
        end)

        it('should not print with explicit category: default', function ()
          err("message1")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

    end)

    describe('(flow category inactive)', function ()
      local old_active_categories_flow = debug.active_categories.flow

      setup(function ()
        debug.active_categories.flow = false
      end)

      teardown(function ()
        debug.active_categories.flow = old_active_categories_flow
      end)

      describe('warn', function ()

        it('should not print with explicit category: flow', function ()
          warn("message1", "flow")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

      describe('err', function ()

        it('should not print with explicit category: flow', function ()
          err("message1", "flow")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

    end)

  end)

  describe('(debug level set to error)', function ()
    setup(function ()
      debug.current_level = debug.level.error
    end)

    teardown(function ()
      debug.current_level = debug.level.none
    end)


    describe('log', function ()

      it('should never print', function ()
        log("message1")
        log("message1", "default")
        log("message1", "flow")
        assert.spy(printh_stub).was.not_called()
      end)

    end)

    describe('warn', function ()

      it('should never print', function ()
        warn("message1")
        warn("message1", "default")
        warn("message1", "flow")
        assert.spy(printh_stub).was.not_called()
      end)

    end)

    describe('(default category active)', function ()
      local old_active_categories_default = debug.active_categories.default

      setup(function ()
        debug.active_categories.default = true
      end)

      teardown(function ()
        debug.active_categories.default = old_active_categories_default
      end)

      describe('err', function ()

        it('should print with no argument (default)', function ()
          err("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] error: message1")
        end)

        it('should print with explicit category: default', function ()
          err("message1")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[default] error: message1")
        end)

      end)

    end)

    describe('(flow category active)', function ()
      local old_active_categories_flow = debug.active_categories.flow

      setup(function ()
        debug.active_categories.flow = true
      end)

      teardown(function ()
        debug.active_categories.flow = old_active_categories_flow
      end)

      describe('err', function ()

        it('should print with explicit category: flow', function ()
          err("message1", "flow")
          assert.spy(printh_stub).was.called(1)
          assert.spy(printh_stub).was.called_with("[flow] error: message1")
        end)

      end)

    end)

    describe('(default category inactive)', function ()
      local old_active_categories_default = debug.active_categories.default

      setup(function ()
        debug.active_categories.default = false
      end)

      teardown(function ()
        debug.active_categories.default = old_active_categories_default
      end)

      describe('err', function ()

        it('should not print with no argument (default)', function ()
          err("message1")
          assert.spy(printh_stub).was.not_called()
        end)

        it('should not print with explicit category: default', function ()
          err("message1")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

    end)

    describe('(flow category inactive)', function ()
      local old_active_categories_flow = debug.active_categories.flow

      setup(function ()
        debug.active_categories.flow = false
      end)

      teardown(function ()
        debug.active_categories.flow = old_active_categories_flow
      end)

      describe('err', function ()

        it('should not print with explicit category: flow', function ()
          err("message1", "flow")
          assert.spy(printh_stub).was.not_called()
        end)

      end)

    end)

  end)

  describe('(debug level set to none)', function ()

    describe('log', function ()

      it('should never print', function ()
        log("message1")
        log("message1", "default")
        log("message1", "flow")
        assert.spy(printh_stub).was.not_called()
      end)

    end)

    describe('warn', function ()

      it('should never print', function ()
        warn("message1")
        warn("message1", "default")
        warn("message1", "flow")
        assert.spy(printh_stub).was.not_called()
      end)

    end)

    describe('err', function ()

      it('should never print', function ()
        err("message1")
        err("message1", "default")
        err("message1", "flow")
        assert.spy(printh_stub).was.not_called()
      end)

    end)

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

describe('dump', function ()

  debug.dump_max_recursion_level = 2

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
