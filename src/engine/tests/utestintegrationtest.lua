require("engine/test/bustedhelper")
require("engine/core/helper")
require("engine/render/color")
local gameapp = require("engine/application/gameapp")
local integrationtest = require("engine/test/integrationtest")
local itest_manager, integration_test, time_trigger = integrationtest.itest_manager, integrationtest.integration_test, integrationtest.time_trigger
local logging = require("engine/debug/logging")
local input = require("engine/input/input")

local function repeat_callback(time, callback)
  -- ceil is just for times with precision of 0.01 or deeper,
  -- so the last frame is reached (e.g. an action at t=0.01 is applied)
  -- caution: this may make fractional times advance too much and apply actions they shouldn't,
  -- so tune your times carefully for testing
  for i = 1, ceil(time*fps) do
   callback()
  end
end


describe('itest_manager', function ()

  after_each(function ()
    itest_manager:init()
  end)

  describe('init', function ()

    it('should create a singleton instance with empty itests', function ()
      assert.are_same({}, itest_manager.itests)
    end)

  end)

  describe('register_itest', function ()

    it('should register a new test', function ()
      local function setup_fn() end
      local function action1() end
      local function action2() end
      local function action3() end
      local function action4() end
      local function final_assert_fn() end
      itest_manager:register_itest('test 1', {'titlemenu'}, function ()
        setup_callback(setup_fn)
        act(action1)  -- test immediate action
        wait(0.5)
        wait(0.6)     -- test closing previous wait
        act(action2)  -- test action with previous wait
        act(action3)  -- test immediate action
        add_action(time_trigger(1.0), action4)  -- test retro-compatible function
        wait(0.7)     -- test wait-action closure
        final_assert(final_assert_fn)
      end)
      local created_itest = itest_manager.itests[1]
      assert.are_same({
          'test 1',
          {'titlemenu'},
          setup_fn,
          {
            scripted_action(time_trigger(0.0), action1),
            scripted_action(time_trigger(0.5), dummy),
            scripted_action(time_trigger(0.6), action2),
            scripted_action(time_trigger(0.0), action3),
            scripted_action(time_trigger(1.0), action4),
            scripted_action(time_trigger(0.7), dummy)
          },
          final_assert_fn
        },
        {
          created_itest.name,
          created_itest.active_gamestates,
          created_itest.setup,
          created_itest.action_sequence,
          created_itest.final_assertion
        })
    end)

  end)

  describe('register', function ()

    it('should register a new test', function ()
      local itest = integration_test('test 1', {'titlemenu'})
      itest_manager:register(itest)
      assert.are_equal(itest, itest_manager.itests[1])
    end)

    it('should register a 2nd test', function ()
      local itest = integration_test('test 1', {'titlemenu'})
      local itest2 = integration_test('test 2', {'titlemenu'})
      itest_manager:register(itest)
      itest_manager:register(itest2)
      assert.are_same({itest, itest2}, itest_manager.itests)
    end)

  end)

  describe('init_game_and_start_by_index', function ()

    setup(function ()
      itest_runner_own_method = stub(itest_runner, "init_game_and_start")
    end)

    teardown(function ()
      itest_runner_own_method:revert()
    end)

    after_each(function ()
      itest_runner_own_method:clear()
    end)

    it('should delegate to itest runner', function ()
      local itest = integration_test('test 1', {'titlemenu'})
      itest_manager:register(itest)
      itest_manager:init_game_and_start_by_index(1)
      assert.spy(itest_runner_own_method).was_called(1)
      assert.spy(itest_runner_own_method).was_called_with(match.ref(itest_runner), itest)
    end)

    it('should assert if the index is invalid', function ()
      local itest = integration_test('test 1', {'titlemenu'})
      itest_manager:register(itest)
      assert.has_error(function ()
        itest_manager:init_game_and_start_by_index(2)
      end,
      "itest_manager:init_game_and_start_by_index: index is 2 but only 1 were registered.")
    end)

  end)

end)


describe('itest_runner', function ()

  -- prepare mock app with default implementation
  local mock_app = gameapp()

  local test

  before_each(function ()
    test = integration_test('character walks', {'stage'})
  end)

  after_each(function ()
    -- full reset
    itest_runner:init()
    input.mode = input_modes.native
    logging.logger:init()
  end)

  describe('init', function ()

    it('should initialize parameters', function ()
      assert.are_same({
          false,
          nil,
          0,
          0,
          1,
          test_states.none,
          nil,
          nil
        },
        {
          itest_runner.initialized,
          itest_runner.current_test,
          itest_runner.current_frame,
          itest_runner._last_trigger_frame,
          itest_runner._next_action_index,
          itest_runner.current_state,
          itest_runner.current_message,
          itest_runner.gameapp
        })
    end)

  end)

  describe('init_game_and_start', function ()

    setup(function ()
      stub(gameapp, "reset")
      stub(gameapp, "start")
      stub(itest_runner, "stop")
      stub(itest_runner, "start")
    end)

    teardown(function ()
      gameapp.reset:revert()
      gameapp.start:revert()
      itest_runner.stop:revert()
      itest_runner.start:revert()
    end)

    after_each(function ()
      gameapp.reset:clear()
      gameapp.start:clear()
      itest_runner.stop:clear()
      itest_runner.start:clear()
    end)

    it('should error if app is not set', function ()

      assert.has_error(function ()
        itest_runner:init_game_and_start(test)
      end, "itest_runner:init_game_and_start: self.app is not set")
    end)

    describe('(with mock app)', function ()

      before_each(function ()
        itest_runner.app = mock_app
      end)

      describe('(when current_test is already set)', function ()

        before_each(function ()
          itest_runner.current_test = test
        end)

        it('should reset the app', function ()
          itest_runner:init_game_and_start(test)

          local s = assert.spy(gameapp.reset)
          s.was_called(1)
          s.was_called_with(match.ref(mock_app))
        end)

        it('should stop', function ()
          itest_runner:init_game_and_start(test)

          local s = assert.spy(itest_runner.stop)
          s.was_called(1)
          s.was_called_with(match.ref(itest_runner))
        end)

      end)

      it('should start the gameapp', function ()
        itest_runner:init_game_and_start(test)

        local s = assert.spy(gameapp.start)
        s.was_called(1)
        s.was_called_with(match.ref(mock_app))
      end)

      it('should init a set gameapp and the passed test', function ()
        itest_runner:init_game_and_start(test)

        local s = assert.spy(itest_runner.start)
        s.was_called(1)
        s.was_called_with(match.ref(itest_runner), test)
      end)

    end)

  end)

  describe('(with mock app)', function ()

    before_each(function ()
      itest_runner.app = mock_app
    end)

    describe('update_game_and_test', function ()

      setup(function ()
        stub(gameapp, "update")
        spy.on(itest_runner, "update")
      end)

      teardown(function ()
        gameapp.update:revert()
        itest_runner.update:revert()
      end)

      after_each(function ()
        gameapp.update:clear()
        itest_runner.update:clear()
      end)

      describe('(when state is not running)', function ()

        it('should do nothing', function ()
          itest_runner:update_game_and_test()
          assert.spy(gameapp.update).was_not_called()
          assert.spy(itest_runner.update).was_not_called()
        end)

      end)

      describe('(when state is running for some actions)', function ()

        before_each(function ()
          test:add_action(time_trigger(1.0), function () end, 'some_action')
        end)

        it('should update the set gameapp and the passed test', function ()
          itest_runner:start(test)

          itest_runner:update_game_and_test()

          local s_app = assert.spy(gameapp.update)
          s_app.was_called(1)
          s_app.was_called_with(match.ref(mock_app))
          local s_runner = assert.spy(itest_runner.update)
          s_runner.was_called(1)
          s_runner.was_called_with(match.ref(itest_runner))
        end)

      end)

      describe('(when running, and test ends on this update with success)', function ()

        before_each(function ()
          test:add_action(time_trigger(0.017), function () end, 'some_action')
          itest_runner:start(test)
        end)

        setup(function ()
          stub(_G, "log")
        end)

        teardown(function ()
          log:revert()
        end)

        after_each(function ()
          log:clear()
        end)

        it('should only log the result', function ()
          itest_runner:update_game_and_test()
          local s = assert.spy(log)
          s.was_called()  -- we only want 1 call, but we check "at least once" because there are other unrelated logs
          s.was_called_with("itest 'character walks' ended with success", "itest")
        end)

      end)

      describe('(when running, and test ends on this update with failure)', function ()

        before_each(function ()
          test:add_action(time_trigger(0.017), function () end, 'some_action')
          test.final_assertion = function ()
            return false, "character walks failed"
          end
            itest_runner:start(test)
        end)

        setup(function ()
          stub(_G, "log")
        end)

        teardown(function ()
          log:revert()
        end)

        after_each(function ()
          log:clear()
        end)

        it('should log the result and failure message', function ()
          itest_runner:update_game_and_test()
          local s = assert.spy(log)
          s.was_called()  -- we only want 2 calls, but we check "at least twice" because there are other unrelated logs
          s.was_called_with("itest 'character walks' ended with failure", "itest")
          s.was_called_with("failed: character walks failed", "itest")
        end)

      end)

    end)

    describe('draw_game_and_test', function ()

      setup(function ()
        stub(gameapp, "draw")
        stub(itest_runner, "draw")
      end)

      teardown(function ()
        gameapp.draw:revert()
        itest_runner.draw:revert()
      end)

      after_each(function ()
        gameapp.draw:clear()
        itest_runner.draw:clear()
      end)

      it('should draw the gameapp and the passed test information', function ()
        itest_runner:draw_game_and_test()

        local s_app = assert.spy(gameapp.draw)
        s_app.was_called(1)
        s_app.was_called_with(match.ref(mock_app))
        local s_runner = assert.spy(itest_runner.draw)
        s_runner.was_called(1)
        s_runner.was_called_with(match.ref(itest_runner))
      end)

    end)

  end)  -- (with mock app)

  describe('start', function ()

    setup(function ()
      spy.on(itest_runner, "_initialize")
      spy.on(itest_runner, "_check_end")
      spy.on(itest_runner, "_check_next_action")
    end)

    teardown(function ()
      itest_runner._initialize:revert()
      itest_runner._check_end:revert()
      itest_runner._check_next_action:revert()
    end)

    before_each(function ()
      test.setup = spy.new(function () end)
    end)

    after_each(function ()
      itest_runner._initialize:clear()
      itest_runner._check_end:clear()
      itest_runner._check_next_action:clear()
    end)

    it('should set the current test to the passed test', function ()
      itest_runner:start(test)
      assert.are_equal(test, itest_runner.current_test)
    end)

    it('should initialize state vars', function ()
      itest_runner:start(test)
      assert.are_same({0, 0, 1}, {
        itest_runner.current_frame,
        itest_runner._last_trigger_frame,
        itest_runner._next_action_index
      })
    end)

    it('should call the test setup callback', function ()
      itest_runner:start(test)
      assert.spy(test.setup).was_called(1)
      assert.spy(test.setup).was_called_with()
    end)

    it('should call _initialize the first time', function ()
      itest_runner:start(test)
      assert.spy(itest_runner._initialize).was_called(1)
      assert.spy(itest_runner._initialize).was_called_with(match.ref(itest_runner))
    end)

    it('should call _check_end', function ()
      itest_runner:start(test)
      assert.spy(itest_runner._check_end).was_called(1)
      assert.spy(itest_runner._check_end).was_called_with(match.ref(itest_runner))
    end)

    describe('(when no actions)', function ()

      it('should not check the next action', function ()
        itest_runner:start(test)
        assert.spy(itest_runner._check_next_action).was_not_called()
      end)

      it('should immediately end the run (result depends on final assertion)', function ()
        itest_runner:start(test)
        assert.are_not_equal(test_states.running, itest_runner.current_state)
      end)

    end)

    describe('(when some actions)', function ()

      before_each(function ()
        test:add_action(time_trigger(1.0), function () end, 'some_action')
      end)

      it('should check the next action immediately (if at time 0, will also call it)', function ()
        itest_runner:start(test)
        assert.spy(itest_runner._check_next_action).was_called(1)
        assert.spy(itest_runner._check_next_action).was_called_with(match.ref(itest_runner))
      end)

      it('should enter running state', function ()
        itest_runner:start(test)
        assert.are_equal(test_states.running, itest_runner.current_state)
      end)

    end)

    describe('(after a first start)', function ()

      before_each(function ()
        test:add_action(time_trigger(1.0), function () end, 'restart_action')
        -- some progress
        itest_runner:start(test)
        repeat_callback(1.0, function ()
          itest_runner:update()
        end)
      end)

      it('should not call _initialize the second time', function ()
        -- in this specific case, start was called in before_each so we need to clear manually
        -- just before we call start ourselves to have the correct count
        itest_runner._initialize:clear()
        itest_runner:start(test)
        assert.spy(itest_runner._initialize).was_not_called()
      end)

    end)

  end)

  describe('update', function ()

    it('should assert when no test has been started', function ()
      assert.has_error(function()
        itest_runner:update()
      end,
      "itest_runner:update: current_test is not set")
    end)

    describe('(after test started)', function ()

      local action_callback = spy.new(function () end)

      before_each(function ()
        -- need at least 1/60=0.1666s above 1.0s so it's not called after 1.0s converted to frames
        test:add_action(time_trigger(1.02), action_callback, 'update_test_action')
      end)

      teardown(function ()
        action_callback:revert()
      end)

      before_each(function ()
        itest_runner:start(test)
      end)

      after_each(function ()
        action_callback:clear()
      end)

      it('should advance the current time by 1', function ()
        itest_runner:update()
        assert.are_equal(1, itest_runner.current_frame)
      end)

      it('should call an initial action (t=0.) immediately, preserving last trigger time to 0 and incrementing the _next_action_index', function ()
        itest_runner:update()
        assert.spy(action_callback).was_not_called()
        assert.are_equal(0., itest_runner._last_trigger_frame)
        assert.are_equal(1, itest_runner._next_action_index)
      end)

      it('should not call a later action (t=1.02) before the expected time (1.0s)', function ()
        repeat_callback(1.0, function ()
          itest_runner:update()
        end)
        assert.spy(action_callback).was_not_called()
        assert.are_equal(0., itest_runner._last_trigger_frame)
        assert.are_equal(1, itest_runner._next_action_index)
      end)

      it('should call a later action (t=1.02) after the action time has been reached', function ()
        repeat_callback(1.02, function ()
          itest_runner:update()
        end)
        assert.spy(action_callback).was_called(1)
        assert.are_equal(61, itest_runner._last_trigger_frame)
        assert.are_equal(2, itest_runner._next_action_index)
      end)

      it('should end the test once the last action has been applied', function ()
        repeat_callback(1.02, function ()
          itest_runner:update()
        end)
        assert.are_equal(test_states.success, itest_runner.current_state)
        assert.are_equal(2, itest_runner._next_action_index)
      end)

      describe('(with timeout set to 2s and more actions after that, usually unmet conditions)', function ()

        before_each(function ()
          test:add_action(time_trigger(3.0), function () end, 'more action')
          test:set_timeout(2.0)
        end)

        describe('(when next frame is below 120)', function ()

          before_each(function ()
            itest_runner.current_frame = 118
          end)

          it('should call next action (no time out)', function ()
            itest_runner:update()
            assert.are_equal(test_states.running, itest_runner.current_state)
            assert.spy(action_callback).was_called(1)
          end)

        end)

        describe('(when next frame is 120 or above)', function ()

          before_each(function ()
            itest_runner.current_frame = 119
          end)

          it('should time out without calling next action', function ()
            itest_runner:update()
            assert.are_equal(test_states.timeout, itest_runner.current_state)
            assert.spy(action_callback).was_not_called()
          end)

        end)

      end)

    end)

    describe('(after test ended)', function ()

      before_each(function ()
        -- without any action, start should end the test immediately
        itest_runner:start(test)
      end)

      it('should do nothing', function ()
        assert.are_equal(itest_runner.current_state, test_states.success)
        assert.has_no_errors(function () itest_runner:update() end)
        assert.are_equal(itest_runner.current_state, test_states.success)
      end)

    end)

  end)

  describe('draw', function ()

    describe('(stubbing api.print)', function ()

      setup(function ()
        stub(api, "print")
      end)

      teardown(function ()
        api.print:revert()
      end)

      after_each(function ()
        api.print:clear()
      end)

      it('should draw "no itest running"', function ()
        itest_runner:draw()
        local s = assert.spy(api.print)
        s.was_called(1)
        s.was_called_with("no itest running", 8, 8, colors.white)
      end)

      describe('(when current test is set)', function ()

        before_each(function ()
          itest_runner.current_test = test
          itest_runner.current_state = test_states.running
        end)

        it('should draw information on the current test', function ()
          itest_runner:draw()
          assert.spy(api.print).was_called(2)
        end)

      end)

    end)

  end)

  describe('_get_test_state_color', function ()

    it('should return white for none', function ()
      assert.are_equal(colors.white, itest_runner:_get_test_state_color(test_states.none))
    end)

    it('should return white for none', function ()
      assert.are_equal(colors.white, itest_runner:_get_test_state_color(test_states.running))
    end)

    it('should return green for success', function ()
      assert.are_equal(colors.green, itest_runner:_get_test_state_color(test_states.success))
    end)

    it('should return red for failure', function ()
      assert.are_equal(colors.red, itest_runner:_get_test_state_color(test_states.failure))
    end)

    it('should return dark purple for timeout', function ()
      assert.are_equal(colors.dark_purple, itest_runner:_get_test_state_color(test_states.timeout))
    end)

  end)

  describe('_initialize', function ()

    it('should set the input mode to simulated', function ()
      itest_runner:_initialize()
      assert.are_equal(input_modes.simulated, input.mode)
    end)

    it('should set all logger categories (except itest, but that\'s only visible in pico8 build)', function ()
      itest_runner:_initialize()
      -- hack until we implement #82 TEST integration-busted-trace-build-system
      -- since "trace" is not set in data but in code in _initialize,
      --  it promises to change often during development so we "hide" such tuning in code
      logging.logger.active_categories["trace"] = false
      assert.are_same({
          default = false,
          flow = false,
          player = false,
          ui = false,
          codetuner = false,
          itest = true,    -- now true for both pico8 and busted tests
          trace = false    -- forced to false for this test
        },
        logging.logger.active_categories)
    end)

    it('should set initialized to true', function ()
      itest_runner:_initialize()
      assert.is_true(itest_runner.initialized)
    end)

  end)


  describe('_check_next_action', function ()

    describe('(with dummy action after 1s)', function ()

      local action_callback = spy.new(function () end)
      local action_callback2 = spy.new(function () end)

      setup(function ()
        -- don't stub a function if the return value matters, as in start
        spy.on(itest_runner, "_check_end")
      end)

      teardown(function ()
        action_callback:revert()
        action_callback2:revert()
        itest_runner._check_end:revert()
      end)

      before_each(function ()
        itest_runner:start(test)
        test:add_action(time_trigger(1.0), action_callback, 'action_callback')
      end)

      after_each(function ()
        action_callback:clear()
        action_callback2:clear()
        itest_runner._check_end:clear()
      end)

      describe('(when next action index is 1/1)', function ()

        before_each(function ()
          itest_runner._next_action_index = 1
        end)

        describe('(when next action time trigger is not reached yet)', function ()

          before_each(function ()
            -- time trigger uses relative frames, so compare the difference since last trigger to 60
            itest_runner.current_frame = 158
            itest_runner._last_trigger_frame = 100
          end)

          it('should not call the action nor advance the time/index', function ()
            itest_runner._check_end:clear()  -- was called on start in before_each
            itest_runner:_check_next_action()
            assert.spy(action_callback).was_not_called()
            assert.are_equal(100, itest_runner._last_trigger_frame)
            assert.are_equal(1, itest_runner._next_action_index)
            assert.spy(itest_runner._check_end).was_not_called()
          end)

        end)

        describe('(when next action time trigger is reached)', function ()

          before_each(function ()
            -- time trigger uses relative frames, so compare the difference since last trigger to 60
            itest_runner.current_frame = 160
            itest_runner._last_trigger_frame = 100
          end)

          it('should call the action and advance the timeindex', function ()
            itest_runner._check_end:clear()  -- was called on start in before_each
            itest_runner:_check_next_action()
            assert.spy(action_callback).was_called(1)
            assert.spy(action_callback).was_called_with()
            assert.are_equal(160, itest_runner._last_trigger_frame)
            assert.are_equal(2, itest_runner._next_action_index)
            assert.spy(itest_runner._check_end).was_called(1)
            assert.spy(itest_runner._check_end).was_called_with(match.ref(itest_runner))
          end)

        end)

      end)

      describe('(when next action index is 2/1)', function ()

        before_each(function ()
          -- we still have the dummy action from the outer scope
          itest_runner._next_action_index = 2  -- we are now at 2/1
        end)

        it('should assert', function ()
          assert.has_error(function ()
            itest_runner:_check_next_action()
          end,
          "self._next_action_index (2) is out of bounds for self.current_test.action_sequence (size 1)")
        end)

      end)

      describe('(with 2nd dummy action immediately after the other)', function ()

        describe('(when next action index is 1/1)', function ()

          before_each(function ()
            itest_runner._next_action_index = 1
          end)

          describe('(when next action time trigger is not reached yet)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.0), action_callback2, 'action_callback2')
              itest_runner.current_frame = 158
              itest_runner._last_trigger_frame = 100
            end)

            it('should not call any actions nor advance the time/index', function ()
              itest_runner._check_end:clear()  -- was called on start in before_each
              itest_runner:_check_next_action()
              assert.spy(action_callback).was_not_called()
              assert.spy(action_callback2).was_not_called()
              assert.are_equal(100, itest_runner._last_trigger_frame)
              assert.are_equal(1, itest_runner._next_action_index)
              assert.spy(itest_runner._check_end).was_not_called()
            end)

          end)

          describe('(when next action time trigger is reached)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.0), action_callback2, 'action_callback2')
              itest_runner.current_frame = 160
              itest_runner._last_trigger_frame = 100
            end)

            it('should call both actions and advance the timeindex by 2', function ()
              itest_runner._check_end:clear()  -- was called on start in before_each
              itest_runner:_check_next_action()
              assert.spy(action_callback).was_called(1)
              assert.spy(action_callback).was_called_with()
              assert.spy(action_callback2).was_called(1)  -- thx to action chaining when next action time is 0
              assert.spy(action_callback2).was_called_with()
              assert.are_equal(160, itest_runner._last_trigger_frame)
              assert.are_equal(3, itest_runner._next_action_index)  -- after action 2
              assert.spy(itest_runner._check_end).was_called(2)     -- checked after each action
              assert.spy(itest_runner._check_end).was_called_with(match.ref(itest_runner))
            end)

          end)

        end)

      end)

      describe('(with 2nd dummy action some frames after the other)', function ()

        describe('(when next action index is 1/1)', function ()

          before_each(function ()
            itest_runner._next_action_index = 1
          end)

          describe('(when next action time trigger is not reached yet)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.2), action_callback2, 'action_callback2')
              itest_runner.current_frame = 158
              itest_runner._last_trigger_frame = 100
            end)

            it('should not call any actions nor advance the time/index', function ()
              itest_runner._check_end:clear()  -- was called on start in before_each
              itest_runner:_check_next_action()
              assert.spy(action_callback).was_not_called()
              assert.spy(action_callback2).was_not_called()
              assert.are_equal(100, itest_runner._last_trigger_frame)
              assert.are_equal(1, itest_runner._next_action_index)
              assert.spy(itest_runner._check_end).was_not_called()
            end)

          end)

          describe('(when next action time trigger is reached)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.2), action_callback2, 'action_callback2')
              itest_runner.current_frame = 160
              itest_runner._last_trigger_frame = 100
            end)

            it('should call only the first action and advance the timeindex', function ()
              itest_runner._check_end:clear()  -- was called on start in before_each
              itest_runner:_check_next_action()
              assert.spy(action_callback).was_called(1)
              assert.spy(action_callback).was_called_with()
              assert.spy(action_callback2).was_not_called()  -- at least 1 frame before action2, no action chaining
              assert.are_equal(160, itest_runner._last_trigger_frame)
              assert.are_equal(2, itest_runner._next_action_index)
              assert.spy(itest_runner._check_end).was_called(1)
              assert.spy(itest_runner._check_end).was_called_with(match.ref(itest_runner))
            end)

          end)

        end)

      end)

    end)

    describe('(with empty action)', function ()

      before_each(function ()
        -- empty actions are useful to just wait until the test end and delay the final assertion
        test:add_action(time_trigger(1, true), nil, 'empty action')
      end)

      it('should recognize next empty action and do nothing', function ()
        itest_runner:start(test)
        itest_runner.current_frame = 2  -- to trigger action to do at end of frame 1

        assert.has_no_errors(function ()
          itest_runner:_check_next_action()
        end)
      end)

    end)

  end)

  describe('_check_end', function ()

    before_each(function ()
      itest_runner:start(test)
    end)

    describe('(when no actions left)', function ()

      describe('(when no final assertion)', function ()

        it('should make test end immediately with success and return true', function ()
          local result = itest_runner:_check_end(test)
          assert.is_true(result)
          assert.are_same({test_states.success, nil},
            {itest_runner.current_state, itest_runner.current_message})
        end)

      end)

      describe('(when final assertion passes)', function ()

        before_each(function ()
          test.final_assertion = function ()
            return true
          end
        end)

        it('should check the final assertion immediately, end with success and return true', function ()
          local result = itest_runner:_check_end(test)
          assert.is_true(result)
          assert.are_same({test_states.success, nil},
            {itest_runner.current_state, itest_runner.current_message})
        end)

      end)

      describe('(when final assertion passes)', function ()

        before_each(function ()
          test.final_assertion = function ()
            return false, "error message"
          end
        end)

        it('should check the final assertion immediately, end with failure and return true', function ()
          local result = itest_runner:_check_end(test)
          assert.is_true(result)
          assert.are_equal(test_states.failure, itest_runner.current_state)
        end)

      end)

    end)

    describe('(when some actions left)', function ()

      before_each(function ()
        test:add_action(time_trigger(1.0), function () end, 'check_end_test_action')
      end)

      it('should return false', function ()
        assert.is_false(itest_runner:_check_end(test))
      end)

    end)

  end)

  describe('_end_with_final_assertion', function ()

    before_each(function ()
      -- inline some parts of itest_runner:start(test)
      --  to get a boilerplate to test on
      -- avoid calling start() directly as it would call _check_end, messing the teardown spy count
      itest_runner:_initialize()
      itest_runner.current_test = test
      itest_runner.current_state = test_states.running
    end)

    describe('(when no final assertion)', function ()

      it('should end with success', function ()
        itest_runner:_end_with_final_assertion(test)
        assert.are_equal(test_states.success, itest_runner.current_state)
      end)

    end)

    describe('(when final assertion passes)', function ()

      before_each(function ()
        test.final_assertion = function ()
          return true
        end
      end)

      it('should check the final assertion and end with success', function ()
        itest_runner:_end_with_final_assertion(test)
        assert.are_equal(test_states.success, itest_runner.current_state)
      end)

    end)

    describe('(when final assertion passes)', function ()

      before_each(function ()
        test.final_assertion = function ()
          return false, "error message"
        end
      end)

      it('should check the final assertion and end with failure', function ()
        itest_runner:_end_with_final_assertion(test)
        assert.are_same({test_states.failure, "error message"},
          {itest_runner.current_state, itest_runner.current_message})
      end)

    end)

  end)

  describe('stop', function ()

    before_each(function ()
      itest_runner:start(test)
    end)

    it('should reset the current test', function ()
      itest_runner:stop(test)
      assert.is_nil(itest_runner.current_test)
    end)

    it('should reset state vars', function ()
      itest_runner:stop(test)
      assert.are_same({0, 0, 1, test_states.none}, {
        itest_runner.current_frame,
        itest_runner._last_trigger_frame,
        itest_runner._next_action_index,
        itest_runner.current_state
      })
    end)


    describe('(when teardown is set)', function ()

      before_each(function ()
        test.teardown = spy.new(function () end)
      end)

      it('should call teardown', function ()
        itest_runner:stop(test)
        assert.spy(test.teardown).was_called(1)
        assert.spy(test.teardown).was_called_with()
      end)

    end)

  end)

end)

describe('time_trigger', function ()

  describe('_init', function ()
    it('should create a time trigger with a time in seconds', function ()
      local time_t = time_trigger(1.0)
      assert.is_not_nil(time_t)
      assert.are_equal(time_t.frames, 60)
    end)
    it('should create a time trigger with a time in frames if wanted', function ()
      local time_t = time_trigger(55, true)
      assert.is_not_nil(time_t)
      assert.are_equal(time_t.frames, 55)
    end)
  end)

  describe('_tostring', function ()
    it('should return "time_trigger({self.time})"', function ()
      assert.are_equal("time_trigger(120)", time_trigger(2.0):_tostring())
    end)
  end)

  describe('_check', function ()
    it('should return true if elapsed time is equal to {self.frames}', function ()
      assert.is_true(time_trigger(2.0):_check(120))
    end)
    it('should return true if elapsed time is greater than {self.frames}', function ()
      assert.is_true(time_trigger(2.0):_check(121))
    end)
    it('should return false if elapsed time is less than {self.frames}', function ()
      assert.is_false(time_trigger(2.0):_check(119))
    end)
  end)

end)

describe('scripted_action', function ()

  describe('_init', function ()
    it('should create a scripted action with a trigger and callback (unnamed)', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2.0), do_something)
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2.0), do_something, "unnamed"}, {act.trigger, act.callback, act.name})
    end)
    it('should create a scripted action with a trigger, callback and name', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2.0), do_something, "do_something")
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2.0), do_something, "do_something"}, {act.trigger, act.callback, act.name})
    end)
  end)

  describe('_tostring', function ()
    it('should return "scripted_action \'unnamed\' @ {self.trigger}"" if no name', function ()
      local act = scripted_action(time_trigger(2.0), function () end)
      assert.are_equal("[scripted_action 'unnamed' @ time_trigger(120)]", act:_tostring())
    end)
    it('should return "scripted_action \'{self.name}\' @ {self.trigger}" if some name', function ()
      local act = scripted_action(time_trigger(2.0), function () end, 'do_something')
      assert.are_equal("[scripted_action 'do_something' @ time_trigger(120)]", act:_tostring())
    end)
  end)
end)


describe('integration_test', function ()

  describe('_init', function ()

    it('should create an integration test with a name (and active gamestates for non-pico8 build)', function ()
      local test = integration_test('character follows ground', {'stage'})
      assert.is_not_nil(test)
      assert.are_same({'character follows ground', nil, {}, nil, 0, {'stage'}},
        {test.name, test.setup, test.action_sequence, test.final_assertion, test.timeout_frames, test.active_gamestates})
    end)

    it('should assert if active gamestates is nil for non-pico8 build', function ()
      assert.has_error(function ()
        integration_test('missing active gamestates')
        end,
        "integration_test._init: non-pico8 build requires active_gamestates to define them at runtime")
    end)

  end)

  describe('_tostring', function ()
    it('should return "integration_test \'{self.name}\'', function ()
      local test = integration_test('character follows ground', function () end)
      assert.are_equal("[integration_test 'character follows ground']", test:_tostring())
    end)
  end)

  describe('add_action', function ()
    it('should add a scripted action in the action sequence', function ()
      local test = integration_test('character follows ground', function () end)
      action_callback = function () end
      test:add_action(time_trigger(1.0), action_callback, 'my_action')
      assert.are_equal(1, #test.action_sequence)
      assert.are_same({time_trigger(1.0), action_callback, 'my_action'}, {test.action_sequence[1].trigger, test.action_sequence[1].callback, test.action_sequence[1].name})
    end)
  end)

  describe('set_timeout', function ()
    it('should set the timeout by converting time in s to frames', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(2.0)
      assert.are_equal(120, test.timeout_frames)
    end)
  end)

  describe('check_timeout', function ()

    it('should return false if timeout is 0', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(0.0)
      assert.is_false(test:check_timeout(50))
    end)

    it('should return false if frame is less than timeout (119 < 120)', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(2.0)
      assert.is_false(test:check_timeout(119))
    end)

    it('should return true if frame is greater than or equal to timeout', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(2.0)
      assert.is_true(test:check_timeout(120))
    end)

  end)

  describe('_check_final_assertion', function ()
    it('should call the final assertion and return the result', function ()
      local test = integration_test('character follows ground', function () end)
      test.final_assertion = function()
        return false, 'error message'
      end
      assert.are_same({false, 'error message'}, {test:_check_final_assertion()})
    end)
  end)


end)
