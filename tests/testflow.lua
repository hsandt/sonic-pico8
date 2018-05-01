picotest = require("picotest")
helper = require("src/helper")
flow = require("src/flow")
titlemenu = require("src/titlemenu")

function run_test()
 picotest.test('gamestates', test_gamestates)
end

function test_gamestates(desc,it)
 desc('flow.add_gamestate', function ()
  flow:add_gamestate(titlemenu.state)
  it('should add a gamestate', function ()
    return flow.gamestates[titlemenu.state.type] == titlemenu.state
  end)
  desc('[after flow.add_gamestate] flow.query_gamestate_type', function ()
   flow:query_gamestate_type(titlemenu.state.type)
   it('should query a new gamestate', function ()
    return flow.next_gamestate == flow.gamestates[titlemenu.state.type]
   end)
   desc('[after flow.add_gamestate, flow.query_gamestate_type] flow.check_next_gamestate', function ()
    flow:check_next_gamestate()
    it('should enter a new gamestate', function ()
     return flow.current_gamestate == flow.gamestates[titlemenu.state.type]
    end)
    it('should clear the next gamestate query', function ()
     return flow.next_gamestate == nil
    end)
    flow.current_gamestate = nil
    flow:query_gamestate_type(titlemenu.state.type) -- restore query
   end)
   desc('[after flow.add_gamestate, flow.query_gamestate_type] flow.change_gamestate', function ()
    flow:change_gamestate(titlemenu.state)
    it('should directly enter a gamestate', function ()
     return flow.current_gamestate == flow.gamestates[titlemenu.state.type]
    end)
    it('should cleanup the now obsolete next gamestate query', function ()
     return flow.next_gamestate == nil
    end)
    flow.current_gamestate = nil
    flow:query_gamestate_type(titlemenu.state.type) -- restore query
   end)
   flow.next_gamestate = nil
  end)
  desc('[after flow.add_gamestate] flow.change_gamestate', function ()
   flow:change_gamestate(titlemenu.state)
   it('should directly enter a gamestate', function ()
    return flow.current_gamestate == flow.gamestates[titlemenu.state.type]
   end)
   flow.current_gamestate = nil
  end)
 end)
 clear_table(flow.gamestates)
end

add(picotest.test_suite, test_gamestates)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
 run_test()
end

-- empty update allows to close test window with ctrl+c
function _update()
end
