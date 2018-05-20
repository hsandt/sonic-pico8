picotest = require("picotest")
titlemenu = require("game/menu/titlemenu")
flow = require("engine/application/flow")
credits = require("game/menu/credits")
stage = require("game/ingame/stage")

function test_titlemenu(desc,it)

  desc('titlemenu.state.type', function ()
    it('should be gamestate_type.titlemenu', function ()
      return titlemenu.state.type == gamestate_type.titlemenu
    end)
  end)

  desc('enter titlemenu state', function ()

    flow:add_gamestate(titlemenu.state)
    flow:add_gamestate(credits.state)
    flow:add_gamestate(stage.state)
    flow:_change_gamestate(titlemenu.state)

    desc('[after enter titlemenu state] titlemenu.state.current_cursor_index', function ()
      it('should be set to 0', function ()
        return titlemenu.state.current_cursor_index == 0
      end)
    end)

    desc('[after enter titlemenu state] titlemenu.state:move_cursor_up', function ()

      titlemenu.state:move_cursor_up()

      it('should not change current_cursor_index due to clamping', function ()
        return titlemenu.state.current_cursor_index == 0
      end)

      titlemenu.state.current_cursor_index = 0

    end)

    desc('[after enter titlemenu state] titlemenu.state:move_cursor_down', function ()

      titlemenu.state:move_cursor_down()

      it('should increase current_cursor_index', function ()
        return titlemenu.state.current_cursor_index == 1
      end)

      titlemenu.state.current_cursor_index = 0

    end)

    desc('[after enter titlemenu state] titlemenu.state:confirm_current_selection', function ()

      titlemenu.state:confirm_current_selection()

      it('should have queried stage state', function ()
        return flow.next_gamestate.type == gamestate_type.stage
      end)

      flow:_change_gamestate(titlemenu.state)
    end)

    desc('[after enter titlemenu state] current_cursor_index = 1', function ()

      titlemenu.state.current_cursor_index = 1

      desc('[after enter titlemenu state, current_cursor_index = 1] titlemenu.state:move_cursor_up', function ()

        titlemenu.state:move_cursor_up()

        it('should decrease current_cursor_index', function ()
          return titlemenu.state.current_cursor_index == 0
        end)

        titlemenu.state.current_cursor_index = 1

      end)

      desc('[after enter titlemenu state, current_cursor_index = 1] titlemenu.state:move_cursor_down', function ()

        titlemenu.state:move_cursor_down()

        it('should not change current_cursor_index due to clamping', function ()
          return titlemenu.state.current_cursor_index == 1
        end)

        titlemenu.state.current_cursor_index = 1

      end)

      desc('[after enter titlemenu state] titlemenu.state:confirm_current_selection', function ()

        titlemenu.state:confirm_current_selection()

        it('should have queried credits state', function ()
          return flow.next_gamestate.type == gamestate_type.credits
        end)

        flow:_change_gamestate(titlemenu.state)

      end)

    end)  -- current_cursor_index = 1
    titlemenu.state.current_cursor_index = 0

  end)  -- enter titlemenu state

end

add(picotest.test_suite, test_titlemenu)


-- pico-8 functions must be placed at the end to be parsed by p8tool correctly

function _init()
  picotest.test('titlemenu', test_titlemenu)
end

-- empty update allows to close test window with ctrl+c on success
function _update()
end
