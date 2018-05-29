require("bustedhelper")
local debug = require("engine/debug/debug")

describe('debug', function ()

  describe('_tostring', function ()

    it('should return "[debug]"', function ()
      assert.are_equal("[debug]", debug:_tostring())
    end)

  end)

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

  end)

  describe('dump', function ()

    debug.dump_max_recursion_level = 2

    -- basic types
    it('nil => "[nil]"', function ()
      assert.are_equal("[nil]", dump(nil))
    end)
    it('"string" => ""string""', function ()
      assert.are_equal("\"string\"", dump("string"))
    end)
    it('true => "true"', function ()
      assert.are_equal("true", dump(true))
    end)
    it('false => "false"', function ()
      assert.are_equal("false", dump(false))
    end)
    it('56 => "56"', function ()
      assert.are_equal("56", dump(56))
    end)
    it('56.2 => "56.2"', function ()
      assert.are_equal("56.2", dump(56.2))
    end)

    -- as key

    it('"string" => "string"', function ()
      assert.are_equal("string", dump("string", true))
    end)
    it('true => "[true]"', function ()
      assert.are_equal("[true]", dump(true, true))
    end)
    it('56.2 => "[56.2]"', function ()
      assert.are_equal("[56.2]", dump(56.2, true))
    end)

    -- tables

    it('{1 nil "string"} => "{[1] = 1 [3] = "string"}"', function ()
      assert.are_equal("{[1] = 1, [3] = \"string\"}", dump({1, nil, "string"}))
    end)

    it('{[7] = 5 string = "other"} => "{[7] = 5, string = "other"}" or "{string = "other", [7] = 5}"', function ()
      -- matchers are difficult to use outside of called_with, so we can't use match.any_of directly
      -- instead we test the alternative with a simple assert.is_true and a custom message to debug if false
      assert.is_true(contains_with_message({"{[7] = 5, string = \"other\"}", "{string = \"other\", [7] = 5}"},
        dump({[7] = 5, string = "other"})))
    end)

    it('{5 "text" string = "other"} => "{[1] = 5 [2] = "text" string = "other"}', function ()
      assert.are_equal("{[1] = 5, [2] = \"text\", string = \"other\"}", dump({5, "text", string = "other"}))
    end)

    it('{...} => "{[1] = 2 mytable = {[1] = 1 [2] = 3 key = "value"}}', function ()
      assert.are_equal("{[1] = 2, mytable = {[1] = 1, [2] = 3, key = \"value\"}}", dump({2, mytable = {1, 3, key = "value"}}))
    end)

    it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = 11}', function ()
      assert.are_equal("{[{[1] = 1, [2] = 3, key = \"value\"}] = 11}", dump({[{1, 3, key = "value"}] = 11}))
    end)

    it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = {[1] = true [2] = false}}', function ()
      assert.are_equal("{[{[1] = 1, [2] = 3, key = \"value\"}] = {[1] = true, [2] = false}}", dump({[{1, 3, key = "value"}] = {true, false}}))
    end)

    -- infinite recursion prevention
    it('{} => [table]', function ()
      assert.are_same({"[table]", "[table]"}, {dump({}, false, 2), dump({}, true, 2)})
    end)
    it('{...} => "{{[1] = 1 [2] = [table] [3] = "rest"} = {idem}', function ()
      assert.are_equal("{[{[1] = 1, [2] = [table], [3] = \"rest\"}] = {[1] = 1, [2] = [table], [3] = \"rest\"}}", dump({[{1, {2, {3, {4}}}, "rest"}] = {1, {2, {3, {4}}}, "rest"}}))
    end)

    -- function

    it('function => "[function]"', function ()
      local f = function ()
      end
      assert.are_same({"[function]", "[function]"}, {dump(f, false), dump(f, true)})
    end)

  end)

end)
