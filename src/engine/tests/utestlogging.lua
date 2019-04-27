require("engine/test/bustedhelper")
require("engine/core/math")
local logging = require("engine/debug/logging")

-- bustedhelper require affects logging, so reset the state
logging.logger:init()

describe('logging', function ()

  local log_msg,   log_stream,   file_log_stream = get_members(logging,
       "log_msg", "log_stream", "file_log_stream")

  describe('log_msg', function ()

    describe('_init', function ()

      it('should create a log_msg with level, category, message content', function ()
        local lm = log_msg(logging.level.info, "character", "moving")
        assert.is_not_nil(lm)
        assert.are_same({logging.level.info, "character", "moving"},
          {lm.level, lm.category, lm.text})
      end)

    end)

    describe('_tostring', function ()

      it('should return "log_msg({self.level}, {self.category}, {self.message})"', function ()
        local lm = log_msg(logging.level.info, "character", "moving")
        assert.are_equal('log_msg(1, "character", "moving")', lm:_tostring())
      end)

    end)

  end)

  describe('compound_message', function ()

    it('should return a string concatenating [category] and message for info', function ()
      local lm = log_msg(logging.level.info, "default", "hello")
      assert.are_equal("[default] hello", logging.compound_message(lm))
    end)

    it('should return a string concatenating [category], log level and message for warning', function ()
      local lm = log_msg(logging.level.warning, "player", "caution")
      assert.are_equal("[player] warning: caution", logging.compound_message(lm))
    end)

    it('should return a string concatenating [category], log level and message for error', function ()
      local lm = log_msg(logging.level.error, "flow", "danger")
      assert.are_equal("[flow] error: danger", logging.compound_message(lm))
    end)

  end)

  describe('log_stream (testing implemented base methods)', function ()

    local dummy_log_stream = derived_singleton(log_stream)

    dummy_log_stream.on_log = spy.new(function () end)

    after_each(function ()
      dummy_log_stream:init()
    end)

    describe('init', function ()

      it('should initialize the singleton active', function ()
        assert.is_true(dummy_log_stream.active)
      end)

    end)

    describe('log', function ()

      teardown(function ()
        dummy_log_stream.on_log:revert()
      end)

      after_each(function ()
        dummy_log_stream.on_log:clear()
      end)

      it('should do nothing is inactive', function ()
        dummy_log_stream.active = false
        local lm = log_msg(logging.level.warning, "player", "caution")
        dummy_log_stream:log(lm)
        assert.spy(dummy_log_stream.on_log).was_called(0)
      end)

      it('should call on_log callback if active', function ()
        local lm = log_msg(logging.level.warning, "player", "caution")
        dummy_log_stream:log(lm)
        assert.spy(dummy_log_stream.on_log).was_called(1)
        assert.spy(dummy_log_stream.on_log).was_called_with(dummy_log_stream, match.ref(lm))
      end)

    end)

  end)

  describe('logger', function ()

    local logger = logging.logger

    after_each(function ()
      logger:init()
    end)

    describe('init', function ()

      it('should set all active categories flags to true, except trace', function ()
        for category, _ in pairs(logger.active_categories) do
          if category == "trace" then
            assert.is_false(logger.active_categories[category], "category '"..category.."' is active")
          else
            assert.is_true(logger.active_categories[category], "category '"..category.."' is not active")
          end
        end
      end)

    end)

    -- for file logging, our tests are low-level and just check that on_log
    -- is calling printh on the compounded message
    describe('file_log_stream', function ()

      local printh_stub

      setup(function ()
        printh_stub = stub(_G, "printh")
      end)

      teardown(function ()
        printh_stub:revert()
      end)

      before_each(function ()
        logger:register_stream(file_log_stream)
      end)

      after_each(function ()
        file_log_stream:init()
        printh_stub:clear()
      end)

      describe('derived_init', function ()
        it('should set file_prefix to "game"', function ()
          assert.are_equal("game", file_log_stream.file_prefix)
        end)
      end)

      describe('clear', function ()
        it('should call printh with empty message and overwrite mode', function ()
          file_log_stream.file_prefix = "my_game"

          file_log_stream:clear()

          assert.spy(printh_stub).was_called(1)
          assert.spy(printh_stub).was_called_with("", "my_game_log", true)
        end)
      end)

      describe('on_log', function ()
        it('should call printh with compounded message and target file "{self.file_prefix}_log.txt"', function ()
          file_log_stream.file_prefix = "my_game"

          local lm = log_msg(logging.level.info, "default", "dummy")
          file_log_stream:on_log(lm)

          assert.spy(printh_stub).was_called(1)
          assert.spy(printh_stub).was_called_with(logging.compound_message(lm), "my_game_log")
        end)
      end)

    end)

    describe('deactivate_all_categories', function ()

      it('should set all active categories flags to false', function ()
        logger:deactivate_all_categories()
        for category, _ in pairs(logger.active_categories) do
          assert.is_false(logger.active_categories[category])
        end
      end)

    end)

    describe('register_stream', function ()

      it('should add a valid stream to the streams', function ()
        local spied_fun = spy.new(function () end)

        local fake_stream = derived_singleton(log_stream)

        function fake_stream:on_log(lm)
            spied_fun(2, lm.level, lm.category, lm.text)
        end

        logger:register_stream(fake_stream)

        -- implementation
        assert.are_same({fake_stream}, logger._streams)

        -- interface
        log("text", "default")
        assert.spy(spied_fun).was_called(1)
        assert.spy(spied_fun).was_called_with(2, logging.level.info, "default", "text")
        assert.spy(spied_fun).was_called_with(2, logging.level.info, "default", "text")
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

      function generate_fake_stream(value)
        local fake_stream = derived_singleton(log_stream)
        function fake_stream:on_log(lm)
            spied_fun(value, lm.level, lm.category, lm.text)
        end
        return fake_stream
      end

      local fake_stream1 = generate_fake_stream(1)
      local fake_stream2 = generate_fake_stream(2)

      setup(function ()
        spy.on(fake_stream1, "log")
        spy.on(fake_stream2, "log")
      end)

      after_each(function ()
        fake_stream1.log:clear()
        fake_stream2.log:clear()
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

          it('should call log on all streams for category A and logging level '..tostr(log_level), function ()
            logger:_generic_log(log_level, "flow", "text")

            -- implementation
            local lm = log_msg(log_level, "flow", "text")
            assert.spy(fake_stream1.log).was_called(1)
            assert.spy(fake_stream1.log).was_called_with(match.ref(fake_stream1), lm)
            assert.spy(fake_stream2.log).was_called(1)
            assert.spy(fake_stream2.log).was_called_with(match.ref(fake_stream2), lm)

            -- interface
            assert.spy(spied_fun).was_called(2)
            assert.spy(spied_fun).was_called_with(1, log_level, "flow", "text")
            assert.spy(spied_fun).was_called_with(2, log_level, "flow", "text")
          end)

        end

        it('should not call log for category B (even for logging level 2)', function ()
          logger:_generic_log(2, "player", "text")

          -- implementation
          assert.spy(fake_stream1.log).was_not_called()
          assert.spy(fake_stream2.log).was_not_called()

          -- interface
          assert.spy(spied_fun).was_not_called()
        end)

        it('should not call log for logging level 1 (even for category B)', function ()
          logger:_generic_log(1, "flow", "text")

          -- implementation
          assert.spy(fake_stream1.log).was_not_called()
          assert.spy(fake_stream2.log).was_not_called()

          -- interface
          assert.spy(spied_fun).was_not_called()
        end)

      end)

    end)

    -- for console logging, our tests are high-level
    -- and contain checking that compound_message is doing its job
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
        logger:register_stream(console_log_stream)
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

      before_each(function ()
        -- no need to teardown, we are inside the 'logger' block that reinit logger after_each
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

      -- as_key: used to mimic key representation in lua tables

      it('"string" => "string"', function ()
        assert.are_equal("string", dump("string", true))
      end)
      it('true => "[true]"', function ()
        assert.are_equal("[true]", dump(true, true))
      end)
      it('56.2 => "[56.2]"', function ()
        assert.are_equal("[56.2]", dump(56.2, true))
      end)

      -- sequence of mixed values

      it('{1 nil "string"} => "{[1] = 1 [3] = "string"}"', function ()
        assert.are_equal("{[1] = 1, [3] = \"string\"}", dump({1, nil, "string"}))
      end)

      -- mix of non-comparable keys (cannot use sorted_keys here)

      it('{[7] = 5 string = "other"} => "{[7] = 5, string = "other"}" or "{string = "other", [7] = 5}"', function ()
        -- matchers are difficult to use outside of called_with, so we can't use match.any_of directly
        -- instead we test the alternative with a simple assert.is_true and a custom message to debug if false
        assert.is_true(contains_with_message({"{[7] = 5, string = \"other\"}", "{string = \"other\", [7] = 5}"},
          dump({[7] = 5, string = "other"})))
      end)

      -- mix of sequence of and indexed values

      it('{5 "text" string = "other"} => "{[1] = 5 [2] = "text" string = "other"}', function ()
        assert.are_equal("{[1] = 5, [2] = \"text\", string = \"other\"}", dump({5, "text", string = "other"}))
      end)

      it('{...} => "{[1] = 2 mytable = {[1] = 1 [2] = 3 key = "value"}}', function ()
        assert.are_equal("{[1] = 2, mytable = {[1] = 1, [2] = 3, key = \"value\"}}", dump({2, mytable = {1, 3, key = "value"}}))
      end)

      -- tables as values

      it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = 11}', function ()
        assert.are_equal("{[{[1] = 1, [2] = 3, key = \"value\"}] = 11}", dump({[{1, 3, key = "value"}] = 11}))
      end)

      it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = {[1] = true [2] = false}}', function ()
        assert.are_equal("{[{[1] = 1, [2] = 3, key = \"value\"}] = {[1] = true, [2] = false}}", dump({[{1, 3, key = "value"}] = {true, false}}))
      end)

      -- sequences with table elements implementing _tostring

      it('{1, "text", vector(2, 4)} => "{[1] = 1, [2] = "text", [3] = vector(2, 4)}"', function ()
        assert.are_equal("{[1] = 1, [2] = \"text\", [3] = vector(2, 4)}", dump({1, "text", vector(2, 4)}, false, 1, true))
      end)

      -- non-sequence tables where ambiguous representation can be made deterministic with sorted_keys
      --   as long as the keys are comparable
      -- note that we are not testing __genOrderedIndex, orderedNext and orderedPairs, so we test them via dump with sorted_keys: true instead

      it('{f = 4, ["0"] = "a", b = -100} => "{[0] = "a", b = -100, f = 4}"', function ()
        assert.are_equal("{0 = \"a\", b = -100, f = 4}", dump({f = 4, ["0"] = "a", b = -100}, false, nil, true, --[[sorted_keys:]] true))
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
        logger.dump_max_recursion_level = 2  -- it is now more, so simulate a default level of 2 manually
        assert.are_equal("{[{[1] = 1, [2] = [table], [3] = \"rest\"}] = {[1] = 1, [2] = [table], [3] = \"rest\"}}", dump({[{1, {2, {3, {4}}}, "rest"}] = {1, {2, {3, {4}}}, "rest"}}))
      end)

      -- function

      it('function => "[function]"', function ()
        local f = function ()
        end
        assert.are_same({"[function]", "[function]"}, {dump(f, false), dump(f, true)})
      end)

    end)

    describe('nice_dump', function ()


      before_each(function ()
        -- no need to teardown, we are inside the 'logger' block that reinit logger after_each
        logger.dump_max_recursion_level = 2
      end)

      it('{1, "text", vector(2, 4)} => "{[1] = 1, [2] = "text", [3] = vector(2, 4)}"', function ()
        assert.are_equal("{[1] = 1, [2] = \"text\", [3] = vector(2, 4)}", nice_dump({1, "text", vector(2, 4)}))
      end)

      it('{[10.5] = "b", [-22] = "a", [34.7] = "c"} => "{[-22] = "a", [10.5] = "b", [34.7] = "c"}"', function ()
        assert.are_equal("{[-22] = \"a\", [10.5] = \"b\", [34.7] = \"c\"}", nice_dump({[10.5] = "b", [-22] = "a", [34.7] = "c"}, true))
      end)

    end)

  end)  -- logger

end)
