require("bustedhelper")
local flow = require("engine/application/flow")
local helper = require("engine/core/helper")
local titlemenu = require("game/menu/titlemenu")
local credits = require("game/menu/credits")

describe('flow', function ()

  describe('_tostring', function ()
    assert.are_equal("[flow]", flow:_tostring())
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
        flow.next_gamestate = nil
      end)

      it('should query a new gamestate with the correct type', function ()
        flow:query_gamestate_type(titlemenu.state.type)
        assert.are_equal(titlemenu.state.type, flow.next_gamestate.type)
      end)

      it('should query a new gamestate with the correct reference', function ()
        flow:query_gamestate_type(titlemenu.state.type)
        assert.are_equal(flow.gamestates[titlemenu.state.type], flow.next_gamestate)
      end)

      it('should assert if a nil gamestate type is passed', function ()
        assert.has_error(function ()
            flow:query_gamestate_type(nil)
          end,
          "flow:query_gamestate_type: passed gamestate_type is nil")
      end)

      describe('(titlemenu state entered)', function ()

        before_each(function ()
          flow:_change_gamestate(titlemenu.state)
        end)

        after_each(function ()
          flow.current_gamestate:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
          flow.current_gamestate = nil
        end)

        it('should assert if the same gamestate type as the current one is passed', function ()
          assert.has_error(function ()
              flow:query_gamestate_type(titlemenu.state.type)
            end,
            "flow:query_gamestate_type: cannot query the current gamestate type titlemenu again")
        end)

      end)

    end)

    describe('query_gamestate_type', function ()

      before_each(function ()
       flow:query_gamestate_type(titlemenu.state.type)
      end)

      after_each(function ()
        flow.next_gamestate = nil
      end)

      describe('_check_next_gamestate', function ()

        before_each(function ()
          flow:_check_next_gamestate()
        end)

        after_each(function ()
          flow.current_gamestate:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
          flow.current_gamestate = nil
        end)

        it('should enter a new gamestate with the correct type', function ()
          assert.are_equal(titlemenu.state.type, flow.current_gamestate.type)
        end)

        it('should enter a new gamestate with the correct reference', function ()
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.current_gamestate)
        end)

        it('should clear the next gamestate query', function ()
          assert.is_nil(flow.next_gamestate)
        end)

      end)

      describe('update', function ()

        before_each(function ()
          flow:update()
        end)

        after_each(function ()
          flow.current_gamestate:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
          flow.current_gamestate = nil
        end)

        it('via _check_next_gamestate enter a new gamestate with the correct type', function ()
          assert.are_equal(titlemenu.state.type, flow.current_gamestate.type)
        end)

        it('via _check_next_gamestate enter a new gamestate with correct reference', function ()
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.current_gamestate)
        end)

        it('via _check_next_gamestate hence clear the next gamestate query', function ()
          assert.is_nil(flow.next_gamestate)
        end)

      end)

      describe('_change_gamestate', function ()

        before_each(function ()
          flow:_change_gamestate(titlemenu.state)
        end)

        after_each(function ()
          flow.current_gamestate:on_exit()  -- just cleanup in case titlemenu on_enter had some side effects, since we didn't stub it
          flow.current_gamestate = nil
        end)

        it('should directly enter a gamestate', function ()
          assert.are_equal(flow.gamestates[titlemenu.state.type], flow.current_gamestate)
          assert.are_equal(titlemenu.state.type, flow.current_gamestate.type)
        end)

        it('should cleanup the now obsolete next gamestate query', function ()
          assert.is_nil(flow.next_gamestate)
        end)

      end)

    end)

    describe('_change_gamestate 1st time', function ()
      local titlemenu_on_enter_stub

      setup(function ()
        titlemenu_on_enter_stub = stub(titlemenu.state, "on_enter")
      end)

      teardown(function ()
        titlemenu_on_enter_stub:revert()
      end)

      before_each(function ()
        flow:_change_gamestate(titlemenu.state)
      end)

      after_each(function ()
        flow.current_gamestate = nil
        titlemenu_on_enter_stub:clear()
      end)

      it('should directly enter a gamestate', function ()
        assert.are_equal(flow.gamestates[titlemenu.state.type], flow.current_gamestate)
      end)

      it('should call the gamestate:on_enter', function ()
        assert.spy(titlemenu_on_enter_stub).was_called(1)
        assert.spy(titlemenu_on_enter_stub).was_called_with(titlemenu.state)
      end)

      describe('(credits gamestate added)', function ()

        setup(function ()
          flow:add_gamestate(credits.state)
        end)

        teardown(function ()
          flow.gamestates[credits.state.type] = nil
        end)

        describe('_change_gamestate 2nd time', function ()
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
            flow:_change_gamestate(credits.state)
          end)

          after_each(function ()
            flow.current_gamestate = titlemenu.state
            titlemenu_on_exit_stub:clear()
            credits_on_enter_stub:clear()
          end)

          it('should directly enter another gamestate', function ()
            assert.are_equal(flow.gamestates[credits.state.type], flow.current_gamestate)
          end)

          it('should call the old gamestate:on_exit', function ()
            assert.spy(titlemenu_on_exit_stub).was_called(1)
            assert.spy(titlemenu_on_exit_stub).was_called_with(titlemenu.state)
          end)

          it('should call the new gamestate:on_enter', function ()
            assert.spy(credits_on_enter_stub).was_called(1)
            assert.spy(credits_on_enter_stub).was_called_with(credits.state)
          end)

        end)

      end)  -- (credits gamestate added)

    end)  -- changed gamestate 1st time

  end)  -- (titlemenu gamestate added)

end)
