local picotest = require("picotest")
require("debug")

function test_debug(desc,it)

  desc('log functions', function ()

    it('log should not crash', function ()
      log("message1")
      log("message2", "flow")
      return true
    end)

    it('warn should not crash', function ()
      warn("message1")
      warn("message2", "flow")
      return true
    end)

    it('err should not crash', function ()
      err("message1")
      err("message2", "flow")
      return true
    end)
    
  end)

end

add(picotest.test_suite, test_debug)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('debug', test_debug)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
