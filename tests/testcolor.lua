local picotest = require("picotest")
require("color")

function test_ui(desc,it)

  desc('color_tostring', function ()

    it('should return the name of a known color by index', function ()
      return color_tostring(2) == "dark_purple"
    end)

    it('should return the name of a known color by enum', function ()
      return color_tostring(colors.pink) == "pink"
    end)

    it('should return "unknown color" for nil', function ()
      return color_tostring(nil) == "unknown color"
    end)


    it('should return "unknown color" for -1', function ()
      return color_tostring(-1) == "unknown color"
    end)

    it('should return "unknown color" for 16', function ()
      return color_tostring(16) == "unknown color"
    end)

    it('should return "unknown color" for a table', function ()
      return color_tostring({}) == "unknown color"
    end)

  end)

end

add(picotest.test_suite, test_ui)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('ui', test_ui)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
