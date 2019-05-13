require("engine/test/bustedhelper")
local gameapp = require("engine/application/gameapp")

local flow = require("engine/application/flow")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

describe('gameapp', function ()

  describe('init', function ()

    it('should set empty managers sequence and nil initial gamestate', function ()
      local app = gameapp()
      assert.are_same({{}, nil}, {app.managers, app.initial_gamestate})
    end)

  end)

  describe('(with default app)', function ()

    local app

    local mock_manager1 = {
      start = spy.new(function () end),
      update = spy.new(function () end),
      render = spy.new(function () end)
    }
    local mock_manager2 = {
      start = spy.new(function () end),
      update = spy.new(function () end),
      render = spy.new(function () end)
    }

    before_each(function ()
      app = gameapp()
    end)

    describe('register_managers', function ()

      it('should register each manager passed in variadic arg', function ()
        app:register_managers(mock_manager1, mock_manager2)
        assert.are_same({mock_manager1, mock_manager2}, app.managers)
      end)

    end)

    describe('(with mock_manager1 and mock_manager2 registered)', function ()

      before_each(function ()
        app:register_managers(mock_manager1, mock_manager2)
      end)

      describe('start', function ()

        setup(function ()
          spy.on(gameapp, "register_gamestates")
          spy.on(gameapp, "on_start")
          stub(flow, "query_gamestate_type")
        end)

        teardown(function ()
          gameapp.register_gamestates:revert()
          gameapp.on_start:revert()
          flow.query_gamestate_type:revert()
        end)

        after_each(function ()
          gameapp.register_gamestates:clear()
          gameapp.on_start:clear()
          flow.query_gamestate_type:clear()

          mock_manager1.start:clear()
          mock_manager2.start:clear()
        end)

        it('should assert if initial_gamestate is not set', function ()
          assert.has_error(function ()
            app:start()
          end, "gameapp:start: gameapp.initial_gamestate is not set")
        end)

        describe('(initial gamestate set to "dummy")', function ()

          before_each(function ()
            app.initial_gamestate = "dummy"
          end)

          it('should call register_gamestates', function ()
            app:start()

            assert.spy(gameapp.register_gamestates).was_called(1)
            assert.spy(gameapp.register_gamestates).was_called_with(match.ref(app))
          end)

          it('should call flow:query_gamestate_type with self.initial_gamestate', function ()
            app.initial_gamestate = "dummy_state"

            app:start()

            assert.spy(flow.query_gamestate_type).was_called(1)
            assert.spy(flow.query_gamestate_type).was_called_with(match.ref(flow), "dummy_state")
          end)

          it('should call start on each manager', function ()
            app:start()

            assert.spy(mock_manager1.start).was_called(1)
            assert.spy(mock_manager1.start).was_called_with(match.ref(mock_manager1))
            assert.spy(mock_manager2.start).was_called(1)
            assert.spy(mock_manager2.start).was_called_with(match.ref(mock_manager2))
          end)

          it('should call start on_start', function ()
            app:start()

            assert.spy(gameapp.on_start).was_called(1)
            assert.spy(gameapp.on_start).was_called_with(match.ref(app))
          end)

        end)  -- (initial gamestate set to "dummy")

      end)

      describe('reset', function ()

        setup(function ()
          stub(flow, "init")
          spy.on(gameapp, "on_reset")
        end)

        teardown(function ()
          flow.init:revert()
          gameapp.on_reset:revert()
        end)

        after_each(function ()
          flow.init:clear()
          gameapp.on_reset:clear()
        end)

        it('should call flow:init', function ()
          app:reset()

          assert.spy(flow.init).was_called(1)
          assert.spy(flow.init).was_called_with(match.ref(flow))
        end)

        it('should call on_reset', function ()
          app:reset()

          assert.spy(gameapp.on_reset).was_called(1)
          assert.spy(gameapp.on_reset).was_called_with(match.ref(app))
        end)

      end)

      describe('update', function ()

        setup(function ()
          stub(input, "process_players_inputs")
          stub(flow, "update")
          spy.on(gameapp, "on_update")
        end)

        teardown(function ()
          input.process_players_inputs:revert()
          flow.update:revert()
          gameapp.on_update:revert()
        end)

        after_each(function ()
          input.process_players_inputs:clear()
          flow.update:clear()
          gameapp.on_update:clear()

          mock_manager1.update:clear()
          mock_manager2.update:clear()
        end)

        it('should call input:process_players_inputs', function ()
          app:update()

          local s = assert.spy(input.process_players_inputs)
          s.was_called(1)
          s.was_called_with(match.ref(input))
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should update all registered managers', function ()
          app:update()

          local s1 = assert.spy(mock_manager1.update)
          s1.was_called(1)
          s1.was_called_with(match.ref(mock_manager1))
          local s2 = assert.spy(mock_manager2.update)
          s2.was_called(1)
          s2.was_called_with(match.ref(mock_manager2))
        end)

        it('should update the flow', function ()
          app:update()

          local s2 = assert.spy(flow.update)
          s2.was_called(1)
          s2.was_called_with(match.ref(flow))
        end)

        it('should call on_update', function ()
          app:update()

          local s2 = assert.spy(app.on_update)
          s2.was_called(1)
          s2.was_called_with(match.ref(app))
        end)

      end)

      describe('draw', function ()

        setup(function ()
          stub(_G, "cls")
          stub(flow, "render")
        end)

        teardown(function ()
          cls:revert()
          flow.render:revert()
        end)

        after_each(function ()
          cls:clear()
          flow.render:clear()

          mock_manager1.render:clear()
          mock_manager2.render:clear()
        end)

        it('should clear screen', function ()
          app:draw()
          assert.spy(cls).was_called(1)
        end)

        it('should call flow:render', function ()
          app:draw()
          local s = assert.spy(flow.render)
          s.was_called(1)
          s.was_called_with(match.ref(flow))
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should render all registered managers', function ()
          app:draw()

          local s1 = assert.spy(mock_manager1.render)
          s1.was_called(1)
          s1.was_called_with(match.ref(mock_manager1))
          local s2 = assert.spy(mock_manager2.render)
          s2.was_called(1)
          s2.was_called_with(match.ref(mock_manager2))
        end)

      end)

    end)  -- (with mock_manager1 and mock_manager2 registered)

  end)  -- (with default app)

end)
