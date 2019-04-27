require("engine/test/bustedhelper")
local flow = require("engine/application/flow")
local helper = require("engine/core/helper")
local titlemenu = require("game/menu/titlemenu")
local credits = require("game/menu/credits")

describe('flow', function ()

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
      flow:add_gamestate(titlemenu.state)
      assert.are_equal(titlemenu.state, flow.gamestates[titlemenu.state.type])
    end)

    it('should assert if a nil gamestate is passed', function ()
      assert.has_error(function ()
          flow:add_gamestate(nil)
        end,
        "flow:add_gamestate: passed gamestate is nil")
    end)

  end)

  describe('(titlemenu gamestate added)', function ()

    setup(function ()
      flow:add_gamestate(titlemenu.state)
    end)

    teardown(function ()
      clear_table(flow.gamestates)
    end)

    describe('query_gamestate_type', function ()

      after_each(function ()
        flow.next_state = nil
      end)

      it('should query a new gamestate with the correct type', function ()
        flow:query_gamestate_type(titlemenu.state.type)
        assert.are_equal(titlemenu.state.type, flow.next_state.type)
      end)

      it('should query a new gamestate with the correct reference', function ()
        flow:query_gamestate_type(titlemenu.state.type)
        assert.are_equal(flow.gamestates[titlemenu.state.type], flow.next_state)
      end)

      it('should assert if a nil gamestate type is passed', function ()
        assert.has_error(function ()
            flow:query_gamestate_type(nil)
          end,
          "flow:query_gamestate_type: passed gamestate_type is nil")
      end)

      describe('(titlemenu state entered)', function ()

        before_each(function ()
          flow.curr_state = titlemenu.state
        end)

        after_each(function ()
          flow.curr_state = nil
        end)

        it('should assert if the same gamestate type as the current one is passed', function ()
          assert.has_error(function ()
              flow:query_gamestate_type(titlemenu.state.type)
            end,
            "flow:query_gamestate_type: cannot query the current gamestate type 'titlemenu' itself")
        end)

      end)

    end)

    describe('query_gamestate_type', function ()

      before_each(function ()
       flow:query_gamestate_type(titlemenu.state.type)
      end)

      after_each(function ()
        flow.next_state = nil
      end)

      describe('_check_next_state', function ()

        before_each(function ()
          flow:_check_next_state()
        end)

        after_each(function ()
          flow.curr_state:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
          flow.curr_state = nil
        end)

        it('should enter a new gamestate with the correct type', function ()
          assert.are_equal(titlemenu.state.type, flow.curr_state.type)
        end)

        it('should enter a new gamestate with the correct reference', function ()
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.curr_state)
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
          flow.curr_state:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
          flow.curr_state = nil
        end)

        it('via _check_next_state enter a new gamestate with the correct type', function ()
          assert.are_equal(titlemenu.state.type, flow.curr_state.type)
        end)

        it('via _check_next_state enter a new gamestate with correct reference', function ()
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.curr_state)
        end)

        it('via _check_next_state hence clear the next gamestate query', function ()
          assert.is_nil(flow.next_state)
        end)

      end)

      describe('_change_state', function ()

        after_each(function ()
          if flow.curr_state then
            flow.curr_state:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
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
          flow:_change_state(titlemenu.state)
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.curr_state)
          assert.are_equal(titlemenu.state.type, flow.curr_state.type)
        end)

        it('should cleanup the now obsolete next gamestate query', function ()
          flow:_change_state(titlemenu.state)
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
            flow.curr_state:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
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
          flow:change_gamestate_by_type(titlemenu.state.type)

          -- implementation
          assert.spy(flow._change_state).was_called(1)
          assert.spy(flow._change_state).was_called_with(match.ref(flow), match.ref(titlemenu.state))
          -- interface
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.curr_state)
          assert.are_equal(titlemenu.state.type, flow.curr_state.type)
        end)

      end)

    end)

    describe('_change_state 1st time', function ()
      local titlemenu_on_enter_stub

      setup(function ()
        titlemenu_on_enter_stub = stub(titlemenu.state, "on_enter")
      end)

      teardown(function ()
        titlemenu_on_enter_stub:revert()
      end)

      before_each(function ()
        flow:_change_state(titlemenu.state)
      end)

      after_each(function ()
        flow.curr_state = nil
        titlemenu_on_enter_stub:clear()
      end)

      it('should directly enter a gamestate', function ()
        assert.are_equal(flow.gamestates[titlemenu.state.type], flow.curr_state)
      end)

      it('should call the gamestate:on_enter', function ()
        assert.spy(titlemenu_on_enter_stub).was_called(1)
        assert.spy(titlemenu_on_enter_stub).was_called_with(match.ref(titlemenu.state))
      end)

      describe('(credits gamestate added)', function ()

        setup(function ()
          flow:add_gamestate(credits.state)
        end)

        teardown(function ()
          flow.gamestates[credits.state.type] = nil
        end)

        describe('_change_state 2nd time', function ()
          local titlemenu_on_exit_stub
          local credits_on_enter_stub

          setup(function ()
            titlemenu_on_exit_stub = stub(titlemenu.state, "on_exit")
            credits_on_enter_stub = stub(credits.state, "on_enter")
          end)

          teardown(function ()
            titlemenu_on_exit_stub:revert()
            credits_on_enter_stub:revert()
          end)

          before_each(function ()
            flow:_change_state(credits.state)
          end)

          after_each(function ()
            flow.curr_state = titlemenu.state
            titlemenu_on_exit_stub:clear()
            credits_on_enter_stub:clear()
          end)

          it('should directly enter another gamestate', function ()
            assert.are_equal(flow.gamestates[credits.state.type], flow.curr_state)
          end)

          it('should call the old gamestate:on_exit', function ()
            assert.spy(titlemenu_on_exit_stub).was_called(1)
            assert.spy(titlemenu_on_exit_stub).was_called_with(match.ref(titlemenu.state))
          end)

          it('should call the new gamestate:on_enter', function ()
            assert.spy(credits_on_enter_stub).was_called(1)
            assert.spy(credits_on_enter_stub).was_called_with(match.ref(credits.state))
          end)

        end)

      end)  -- (credits gamestate added)

    end)  -- changed gamestate 1st time

  end)  -- (titlemenu gamestate added)

  describe('render', function ()

    it('should not crash when there is no current gamestate not next gamestate set', function ()
      assert.has_no_errors(function () flow:render() end)
    end)

    describe('(when current gamestate is set)', function ()

      local titlemenu_render_stub

      setup(function ()
        titlemenu_render_stub = stub(titlemenu.state, "render")
      end)

      teardown(function ()
        titlemenu_render_stub:revert()
      end)

      before_each(function ()
        flow:_change_state(titlemenu.state)
      end)

      after_each(function ()
        flow.curr_state:on_exit()
        flow.curr_state = nil
        titlemenu_render_stub:clear()
      end)

      it('should not delegate render to current gamestate', function ()
        flow:render()
        assert.spy(titlemenu_render_stub).was_called(1)
        assert.spy(titlemenu_render_stub).was_called_with(match.ref(titlemenu.state))
      end)

    end)

  end)

end)
