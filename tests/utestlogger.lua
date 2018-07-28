require("bustedhelper")
require("engine/core/math")
local logging = require("engine/debug/logger")

describe('logging', function ()

  describe('compound_message', function ()

    it('should return a string concatenating [category] and message for info', function ()
      assert.are_equal("[default] hello", logging.compound_message("hello", "default", logging.level.info))
    end)

    it('should return a string concatenating [category], log level and message for warning', function ()
      assert.are_equal("[player] warning: caution", logging.compound_message("caution", "player", logging.level.warning))
    end)

    it('should return a string concatenating [category], log level and message for error', function ()
      assert.are_equal("[flow] error: danger", logging.compound_message("danger", "flow", logging.level.error))
    end)

  end)

  describe('logger', function ()

    local logger = logging.logger

    after_each(function ()
      logger:init()
    end)

    describe('deactivate_all_categories', function ()

      it('should set all active categories flags to false', function ()
        for category, _ in pairs(logger.active_categories) do
          assert.is_false(logger.active_categories[category])
        end
      end)

    end)

    describe('register_stream', function ()

      it('should add a valid stream to the streams', function ()
        local spied_fun = spy.new(function () end)

        local stream = {
          var = 2
        }
        function stream:on_log(message, category)
          spied_fun(self.var, message, category)
        end

        logger:register_stream(stream)

        -- implementation
        assert.are_same({stream}, logger._streams)

        -- interface
        log("test", "default")
        assert.spy(spied_fun).was_called(1)
        assert.spy(spied_fun).was_called_with(2, "test", "default")
        assert.spy(spied_fun).was_called_with(2, "test", "default")
      end)

      it('should assert if nil is passed', function ()
        assert.has_error(function ()
            logger:register_stream(nil)
          end,
          "logger:register_stream: passed stream is nil")
      end)

      it('should assert if an invalid stream table is passed', function ()
        -- don't define on_log!
        local invalid_stream = {}

        assert.has_error(function ()
            logger:register_stream(invalid_stream)
          end,
          "logger:register_stream: passed stream is invalid: on_log member is nil or not a callable")
      end)

    end)

    describe('_generic_log', function ()

      local spied_fun = spy.new(function (var, message, category, level) end)

      fake_stream_class = new_class()

      function fake_stream_class:_init(value)
        self.var = value
      end

      function fake_stream_class:on_log(message, category, level)
          spied_fun(self.var, message, category, level)
      end

      local fake_stream1 = fake_stream_class(1)
      local fake_stream2 = fake_stream_class(2)

      setup(function ()
        spy.on(fake_stream1, "on_log")
        spy.on(fake_stream2, "on_log")
      end)

      after_each(function ()
        fake_stream1.on_log:clear()
        fake_stream2.on_log:clear()
        spied_fun:clear()
      end)

      describe('(when category A is active, B inactive and logging level is 2)', function ()

        before_each(function ()
          logger.active_categories.flow = true          -- A
          logger.active_categories.player = false       -- B
          logger.current_level = 2                      -- warning level
          logger:register_stream(fake_stream1)
          logger:register_stream(fake_stream2)
        end)

        -- generate tests for log levels equal to the threshold or higher
        for log_level = 2, 3 do

          it('should call on_log on all streams for category A and logging level '..tostr(log_level), function ()
            logger:_generic_log("test", "flow", log_level)
            -- warn("test", "flow")

            -- implementation
            assert.spy(fake_stream1.on_log).was_called(1)
            assert.spy(fake_stream1.on_log).was_called_with(match.ref(fake_stream1), "test", "flow", log_level)
            assert.spy(fake_stream2.on_log).was_called(1)
            assert.spy(fake_stream2.on_log).was_called_with(match.ref(fake_stream2), "test", "flow", log_level)

            -- interface
            assert.spy(spied_fun).was_called(2)
            assert.spy(spied_fun).was_called_with(1, "test", "flow", log_level)
            assert.spy(spied_fun).was_called_with(2, "test", "flow", log_level)
          end)

        end

        it('should not call on_log for category B (even for logging level 2)', function ()
          logger:_generic_log("test", "player", 2)

          -- implementation
          assert.spy(fake_stream1.on_log).was_not_called()
          assert.spy(fake_stream2.on_log).was_not_called()

          -- interface
          assert.spy(spied_fun).was_not_called()
        end)

        it('should not call on_log for logging level 1 (even for category B)', function ()
          logger:_generic_log("test", "flow", 1)

          -- implementation
          assert.spy(fake_stream1.on_log).was_not_called()
          assert.spy(fake_stream2.on_log).was_not_called()

          -- interface
          assert.spy(spied_fun).was_not_called()
        end)

      end)

    end)

    describe('console logging', function ()

      local printh_stub

      setup(function ()
        printh_stub = stub(_G, "printh")
      end)

      teardown(function ()
        printh_stub:revert()
      end)

      before_each(function ()
        logger.active_categories.flow = true
        logger:register_stream(logging.console_logger)
      end)

      after_each(function ()
        printh_stub:clear()
      end)

      describe('(logger level set to info)', function ()

        before_each(function ()
          logger.current_level = logging.level.info
        end)

        describe('(default category active)', function ()

          before_each(function ()
            logger.active_categories.default = true
          end)

          describe('log', function ()

            it('should print with no argument (default)', function ()
              log("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] message1")
            end)

            it('should print with explicit category: default', function ()
              print("A")
              log("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] message1")
            end)

          end)

          describe('warn', function ()

            it('should print with no argument (default)', function ()
              warn("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] warning: message1")
            end)

            it('should print with explicit category: default', function ()
              warn("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] warning: message1")
            end)

          end)

          describe('err', function ()

            it('should print with no argument (default)', function ()
              err("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] error: message1")
            end)

            it('should print with explicit category: default', function ()
              err("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] error: message1")
            end)

          end)

        end)

        describe('(flow category active)', function ()

          before_each(function ()
            logger.active_categories.flow = true
          end)

          describe('log', function ()

            it('should print with explicit category: flow', function ()
              log("message1", "flow")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[flow] message1")
            end)

          end)

          describe('warn', function ()

            it('should print with explicit category: flow', function ()
              warn("message1", "flow")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[flow] warning: message1")
            end)

          end)

          describe('err', function ()

            it('should print with explicit category: flow', function ()
              err("message1", "flow")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[flow] error: message1")
            end)

          end)

        end)

        describe('(default category inactive)', function ()

          before_each(function ()
            logger.active_categories.default = false
          end)

          describe('log', function ()

            it('should not print with no argument (default)', function ()
              log("message1")
              assert.spy(printh_stub).was_not_called()
            end)

            it('should not print with explicit category: default', function ()
              log("message1")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

          describe('warn', function ()

            it('should not print with no argument (default)', function ()
              warn("message1")
              assert.spy(printh_stub).was_not_called()
            end)

            it('should not print with explicit category: default', function ()
              warn("message1")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

          describe('err', function ()

            it('should not print with no argument (default)', function ()
              err("message1")
              assert.spy(printh_stub).was_not_called()
            end)

            it('should not print with explicit category: default', function ()
              err("message1")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

        end)

        describe('(flow category inactive)', function ()

          before_each(function ()
            logger.active_categories.flow = false
          end)

          describe('log', function ()

            it('should not print with explicit category: flow', function ()
              log("message1", "flow")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

          describe('warn', function ()

            it('should not print with explicit category: flow', function ()
              warn("message1", "flow")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

          describe('err', function ()

            it('should not print with explicit category: flow', function ()
              err("message1", "flow")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

        end)

      end)

      describe('(logger level set to warning)', function ()

        before_each(function ()
          logger.current_level = logging.level.warning
        end)

        describe('log', function ()

          it('should never print', function ()
            log("message1")
            log("message1", "default")
            log("message1", "flow")
            assert.spy(printh_stub).was_not_called()
          end)

        end)

        describe('(default category active)', function ()

          before_each(function ()
            logger.active_categories.default = true
          end)

          describe('warn', function ()

            it('should print with no argument (default)', function ()
              warn("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] warning: message1")
            end)

            it('should print with explicit category: default', function ()
              warn("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] warning: message1")
            end)

          end)

          describe('err', function ()

            it('should print with no argument (default)', function ()
              err("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] error: message1")
            end)

            it('should print with explicit category: default', function ()
              err("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] error: message1")
            end)

          end)

        end)

        describe('(flow category active)', function ()

          before_each(function ()
            logger.active_categories.flow = true
          end)

          describe('warn', function ()

            it('should print with explicit category: flow', function ()
              warn("message1", "flow")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[flow] warning: message1")
            end)

          end)

          describe('err', function ()

            it('should print with explicit category: flow', function ()
              err("message1", "flow")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[flow] error: message1")
            end)

          end)

        end)

        describe('(default category inactive)', function ()

          before_each(function ()
            logger.active_categories.default = false
          end)

          describe('warn', function ()

            it('should not print with no argument (default)', function ()
              warn("message1")
              assert.spy(printh_stub).was_not_called()
            end)

            it('should not print with explicit category: default', function ()
              warn("message1")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

          describe('err', function ()

            it('should not print with no argument (default)', function ()
              err("message1")
              assert.spy(printh_stub).was_not_called()
            end)

            it('should not print with explicit category: default', function ()
              err("message1")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

        end)

        describe('(flow category inactive)', function ()

          before_each(function ()
            logger.active_categories.flow = false
          end)

          describe('warn', function ()

            it('should not print with explicit category: flow', function ()
              warn("message1", "flow")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

          describe('err', function ()

            it('should not print with explicit category: flow', function ()
              err("message1", "flow")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

        end)

      end)

      describe('(logger level set to error)', function ()

        before_each(function ()
          logger.current_level = logging.level.error
        end)

        describe('log', function ()

          it('should never print', function ()
            log("message1")
            log("message1", "default")
            log("message1", "flow")
            assert.spy(printh_stub).was_not_called()
          end)

        end)

        describe('warn', function ()

          it('should never print', function ()
            warn("message1")
            warn("message1", "default")
            warn("message1", "flow")
            assert.spy(printh_stub).was_not_called()
          end)

        end)

        describe('(default category active)', function ()

          before_each(function ()
            logger.active_categories.default = true
          end)

          describe('err', function ()

            it('should print with no argument (default)', function ()
              err("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] error: message1")
            end)

            it('should print with explicit category: default', function ()
              err("message1")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[default] error: message1")
            end)

          end)

        end)

        describe('(flow category active)', function ()

          before_each(function ()
            logger.active_categories.flow = true
          end)

          describe('err', function ()

            it('should print with explicit category: flow', function ()
              err("message1", "flow")
              assert.spy(printh_stub).was_called(1)
              assert.spy(printh_stub).was_called_with("[flow] error: message1")
            end)

          end)

        end)

        describe('(default category inactive)', function ()

          before_each(function ()
            logger.active_categories.default = false
          end)

          describe('err', function ()

            it('should not print with no argument (default)', function ()
              err("message1")
              assert.spy(printh_stub).was_not_called()
            end)

            it('should not print with explicit category: default', function ()
              err("message1")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

        end)

        describe('(flow category inactive)', function ()

          before_each(function ()
            logger.active_categories.flow = false
          end)

          describe('err', function ()

            it('should not print with explicit category: flow', function ()
              err("message1", "flow")
              assert.spy(printh_stub).was_not_called()
            end)

          end)

        end)

      end)

      describe('(logger level set to none)', function ()

        before_each(function ()
          logger.current_level = logging.level.none
        end)

        describe('log', function ()

          it('should never print', function ()
            log("message1")
            log("message1", "default")
            log("message1", "flow")
            assert.spy(printh_stub).was_not_called()
          end)

        end)

        describe('warn', function ()

          it('should never print', function ()
            warn("message1")
            warn("message1", "default")
            warn("message1", "flow")
            assert.spy(printh_stub).was_not_called()
          end)

        end)

        describe('err', function ()

          it('should never print', function ()
            err("message1")
            err("message1", "default")
            err("message1", "flow")
            assert.spy(printh_stub).was_not_called()
          end)

        end)

      end)

    end)

    describe('dump', function ()

      setup(function ()
        logger.dump_max_recursion_level = 2
      end)

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

      -- tables with tostring

      it('{1, "text", vector(2, 4)} => "{[1] = 1, [2] = "text", [3] = vector(2, 4)}"', function ()
        assert.are_equal("{[1] = 1, [2] = \"text\", [3] = vector(2, 4)}", dump({1, "text", vector(2, 4)}, false, 1, true))
      end)

      it('{1, "text", vector(2, 4)} => "{[1] = 1, [2] = "text", [3] = vector(2, 4)}"', function ()
        assert.are_equal("{[1] = 1, [2] = \"text\", [3] = vector(2, 4)}", nice_dump({1, "text", vector(2, 4)}))
      end)

      -- infinite recursion prevention

      it('at level 0: {} => [table]', function ()
        assert.are_same({"[table]", "[table]"}, {dump({}, false, 0), dump({}, true, 0)})
      end)
      it('at level 1: {1, {}} => {1, [table]}', function ()
        assert.are_same({"{[1] = 1, [2] = [table]}", "[{[1] = 1, [2] = [table]}]"}, {dump({1, {}}, false, 1), dump({1, {}}, true, 1)})
      end)
      it('at level 2: {...} => "{{[1] = 1 [2] = [table] [3] = "rest"} = {idem}', function ()
        assert.are_equal("{[{[1] = 1, [2] = [table], [3] = \"rest\"}] = {[1] = 1, [2] = [table], [3] = \"rest\"}}", dump({[{1, {2, {3, {4}}}, "rest"}] = {1, {2, {3, {4}}}, "rest"}}, false, 2))
      end)
      it('without level arg, use default level (2): {...} => "{{[1] = 1 [2] = [table] [3] = "rest"} = {idem}', function ()
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

end)
