require("engine/test/bustedhelper")
local flow = require("engine/application/flow")
local helper = require("engine/core/helper")

describe('flow', function ()

  local mock_gamestate = new_class()

  function mock_gamestate:_init(type)
    self.type = type
  end

  function mock_gamestate:on_enter()
  end

  function mock_gamestate:on_exit()
  end

  function mock_gamestate:update()
  end

  function mock_gamestate:render()
  end

  local mock_gamestate1 = mock_gamestate("mock1")
  local mock_gamestate2 = mock_gamestate("mock2")

  describe('init', function ()
    assert.are_same({{}, nil, nil},
      {flow.gamestates, flow.curr_state, flow.next_state})
  end)

  describe('update', function ()

    it('should not crash when there is no current gamestate not next gamestate set', function ()
      assert.has_no_errors(function () flow:update() end)
    end)

  end)

  describe('add_gamestate', function ()

    after_each(function ()
      clear_table(flow.gamestates)
    end)

    it('should add a gamestate', function ()
      flow:add_gamestate(mock_gamestate1)
      assert.are_equal(mock_gamestate1, flow.gamestates[mock_gamestate1.type])
    end)

    it('should assert if a nil gamestate is passed', function ()
      assert.has_error(function ()
          flow:add_gamestate(nil)
        end,
        "flow:add_gamestate: passed gamestate is nil")
    end)

  end)

  describe('(mock gamestate 1 added)', function ()

    setup(function ()
      flow:add_gamestate(mock_gamestate1)
    end)

    teardown(function ()
      clear_table(flow.gamestates)
    end)

    describe('query_gamestate_type', function ()

      after_each(function ()
        flow.next_state = nil
      end)

      it('should query a new gamestate with the correct type', function ()
        flow:query_gamestate_type(mock_gamestate1.type)
        assert.are_equal(mock_gamestate1.type, flow.next_state.type)
      end)

      it('should query a new gamestate with the correct reference', function ()
        flow:query_gamestate_type(mock_gamestate1.type)
        assert.are_equal(flow.gamestates[mock_gamestate1.type], flow.next_state)
      end)

      it('should assert if a nil gamestate type is passed', function ()
        assert.has_error(function ()
            flow:query_gamestate_type(nil)
          end,
          "flow:query_gamestate_type: passed gamestate_type is nil")
      end)

      describe('(mock gamestate 1 entered)', function ()

        before_each(function ()
          flow.curr_state = mock_gamestate1
        end)

        after_each(function ()
          flow.curr_state = nil
        end)

        it('should assert if the same gamestate type as the current one is passed', function ()
          assert.has_error(function ()
              flow:query_gamestate_type(mock_gamestate1.type)
            end,
            "flow:query_gamestate_type: cannot query the current gamestate type 'mock1' itself")
        end)

      end)

    end)

    describe('query_gamestate_type', function ()

      before_each(function ()
       flow:query_gamestate_type(mock_gamestate1.type)
      end)

      after_each(function ()
        flow.next_state = nil
      end)

      describe('_check_next_state', function ()

        before_each(function ()
          flow:_check_next_state()
        end)

        after_each(function ()
          -- no need to on_exit current state, we know our mock states do nothing
          flow.curr_state = nil
        end)

        it('should enter a new gamestate with the correct type', function ()
          assert.are_equal(mock_gamestate1.type, flow.curr_state.type)
        end)

        it('should enter a new gamestate with the correct reference', function ()
          assert.are_equal(flow.gamestates[mock_gamestate1.type], flow.curr_state)
        end)

        it('should clear the next gamestate query', function ()
          assert.is_nil(flow.next_state)
        end)

      end)

      describe('update', function ()

        before_each(function ()
          flow:update()
        end)

        after_each(function ()
          -- no need to on_exit current state, we know our mock states do nothing
          flow.curr_state = nil
        end)

        it('via _check_next_state enter a new gamestate with the correct type', function ()
          assert.are_equal(mock_gamestate1.type, flow.curr_state.type)
        end)

        it('via _check_next_state enter a new gamestate with correct reference', function ()
          assert.are_equal(flow.gamestates[mock_gamestate1.type], flow.curr_state)
        end)

        it('via _check_next_state hence clear the next gamestate query', function ()
          assert.is_nil(flow.next_state)
        end)

      end)

      describe('_change_state', function ()

        after_each(function ()
          if flow.curr_state then
            -- no need to on_exit current state, we know our mock states do nothing
            flow.curr_state = nil
          end
        end)

        it('should assert if a nil gamestate is passed', function ()
          assert.has_error(function ()
              flow:_change_state(nil)
            end,
            "flow:_change_state: cannot change to nil gamestate")
        end)

        it('should directly enter a gamestate', function ()
          flow:_change_state(mock_gamestate1)
          assert.are_equal(flow.gamestates[mock_gamestate1.type], flow.curr_state)
          assert.are_equal(mock_gamestate1.type, flow.curr_state.type)
        end)

        it('should cleanup the now obsolete next gamestate query', function ()
          flow:_change_state(mock_gamestate1)
          assert.is_nil(flow.next_state)
        end)

      end)

      describe('change_gamestate_by_type (utest only)', function ()


        setup(function ()
          spy.on(flow, "_change_state")
        end)

        teardown(function ()
          flow._change_state:revert()
        end)

        after_each(function ()
          if flow.curr_state then
            -- no need to on_exit current state, we know our mock states do nothing
            flow.curr_state = nil
          end
          flow._change_state:clear()
        end)

        it('should assert if an invalid gamestate type is passed', function ()
          assert.has_error(function ()
              flow:change_gamestate_by_type('invalid')
            end,
            "flow:change_gamestate_by_type: gamestate type 'invalid' has not been added to the flow gamestates")
        end)

        it('should directly enter a gamestate by type', function ()
          flow:change_gamestate_by_type(mock_gamestate1.type)

          -- implementation
          assert.spy(flow._change_state).was_called(1)
          assert.spy(flow._change_state).was_called_with(match.ref(flow), match.ref(mock_gamestate1))
          -- interface
          assert.are_equal(flow.gamestates[mock_gamestate1.type], flow.curr_state)
          assert.are_equal(mock_gamestate1.type, flow.curr_state.type)
        end)

      end)

    end)

    describe('_change_state 1st time', function ()
      local mock_gamestate1_on_enter_stub

      setup(function ()
        mock_gamestate1_on_enter_stub = stub(mock_gamestate1, "on_enter")
      end)

      teardown(function ()
        mock_gamestate1_on_enter_stub:revert()
      end)

      before_each(function ()
        flow:_change_state(mock_gamestate1)
      end)

      after_each(function ()
        flow.curr_state = nil
        mock_gamestate1_on_enter_stub:clear()
      end)

      it('should directly enter a gamestate', function ()
        assert.are_equal(flow.gamestates[mock_gamestate1.type], flow.curr_state)
      end)

      it('should call the gamestate:on_enter', function ()
        assert.spy(mock_gamestate1_on_enter_stub).was_called(1)
        assert.spy(mock_gamestate1_on_enter_stub).was_called_with(match.ref(mock_gamestate1))
      end)

      describe('(mock gamestate 2 added)', function ()

        setup(function ()
          flow:add_gamestate(mock_gamestate2)
        end)

        teardown(function ()
          flow.gamestates[mock_gamestate2.type] = nil
        end)

        describe('_change_state 2nd time', function ()
          local mock_gamestate1_on_exit_stub
          local mock_gamestate2_on_enter_stub

          setup(function ()
            mock_gamestate1_on_exit_stub = stub(mock_gamestate1, "on_exit")
            mock_gamestate2_on_enter_stub = stub(mock_gamestate2, "on_enter")
          end)

          teardown(function ()
            mock_gamestate1_on_exit_stub:revert()
            mock_gamestate2_on_enter_stub:revert()
          end)

          before_each(function ()
            flow:_change_state(mock_gamestate2)
          end)

          after_each(function ()
            flow.curr_state = mock_gamestate1
            mock_gamestate1_on_exit_stub:clear()
            mock_gamestate2_on_enter_stub:clear()
          end)

          it('should directly enter another gamestate', function ()
            assert.are_equal(flow.gamestates[mock_gamestate2.type], flow.curr_state)
          end)

          it('should call the old gamestate:on_exit', function ()
            assert.spy(mock_gamestate1_on_exit_stub).was_called(1)
            assert.spy(mock_gamestate1_on_exit_stub).was_called_with(match.ref(mock_gamestate1))
          end)

          it('should call the new gamestate:on_enter', function ()
            assert.spy(mock_gamestate2_on_enter_stub).was_called(1)
            assert.spy(mock_gamestate2_on_enter_stub).was_called_with(match.ref(mock_gamestate2))
          end)

        end)

      end)  -- (mock_gamestate2 gamestate added)

    end)  -- changed gamestate 1st time

  end)  -- (mock_gamestate1 gamestate added)

  describe('render', function ()

    it('should not crash when there is no current gamestate not next gamestate set', function ()
      assert.has_no_errors(function () flow:render() end)
    end)

    describe('(when current gamestate is set)', function ()

      local mock_gamestate1_render_stub

      setup(function ()
        mock_gamestate1_render_stub = stub(mock_gamestate1, "render")
      end)

      teardown(function ()
        mock_gamestate1_render_stub:revert()
      end)

      before_each(function ()
        flow:_change_state(mock_gamestate1)
      end)

      after_each(function ()
        flow.curr_state:on_exit()
        flow.curr_state = nil
        mock_gamestate1_render_stub:clear()
      end)

      it('should not delegate render to current gamestate', function ()
        flow:render()
        assert.spy(mock_gamestate1_render_stub).was_called(1)
        assert.spy(mock_gamestate1_render_stub).was_called_with(match.ref(mock_gamestate1))
      end)

    end)

  end)

end)
