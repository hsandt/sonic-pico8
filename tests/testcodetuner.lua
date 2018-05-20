local picotest = require("picotest")
local codetuner = require("codetuner")

function test_codetuner(desc,it)

  desc('codetuner.get_spinner_callback', function ()

    codetuner.active = true  -- needed to create tuned vars

    it('should return a function that sets an existing tuned var', function ()
      tuned("myvar", 17)
      local f = codetuner:get_spinner_callback("myvar")
      -- simulate spinner via duck-typing
      local fake_spinnner = {value = 11}
      f(fake_spinnner)
      return codetuner.tuned_vars["myvar"] == 11
    end)

    it('do nothing if it doesn\'t exist', function ()
      codetuner:set_tuned_var("f", 28)
      return codetuner.tuned_vars["f"] == nil
    end)

  end)

  desc('codetuner.get_or_create_tuned_var', function ()

    it('if inactive return default value even if one exists', function ()
      codetuner.active = false
      -- avoid conflicting default values, but this example is to show we use the passed one
      return tuned("a", 12) == 12,
        tuned("a", -12) == -12
    end)

    it('if active and name doesn\'t exist create with default value and return it', function ()
      codetuner.active = true
      local result = tuned("b", 14)
      return codetuner.tuned_vars["b"] == 14,
        result == 14
    end)

    it('if active and name exists return tuned value (default)', function ()
      codetuner.active = true
      tuned("c", 20)
      -- avoid conflicting default values, but this example is to show we use the actual value
      return tuned("c", -20) == 20
    end)

    it('if active and name exists return tuned value (changed)', function ()
      codetuner.active = true
      tuned("d", 20)
      codetuner:set_tuned_var("d", 22)
      return tuned("d", 20) == 22
    end)

  end)

  desc('codetuner.set_tuned_var', function ()

    codetuner.active = true  -- needed to create tuned vars

    it('set tuned value if it exists', function ()
      tuned("e", 24)
      codetuner:set_tuned_var("e", 26)
      return codetuner.tuned_vars["e"] == 26
    end)

    it('do nothing if it doesn\'t exist', function ()
      codetuner:set_tuned_var("f", 28)
      return codetuner.tuned_vars["f"] == nil
    end)

  end)

  clear_table(codetuner.tuned_vars)

  desc('codetuner.init_window', function ()

    codetuner:init_window()

    it('should construct a gui root with a panel of tuned values', function ()
      return codetuner.gui ~= nil,
        codetuner.gui ~= nil and #codetuner.gui.children == 1,
        codetuner.gui ~= nil and #codetuner.gui.children == 1 and
          codetuner.gui.children[1] == codetuner.main_panel

    end)

    it('get_or_create_tuned_var will add corresponding children to the panel', function ()
      tuned("a", 1)
      tuned("b", 2)
      return codetuner.main_panel ~= nil,
        #codetuner.main_panel.children == 2
    end)

  end)

  desc('codetuner.update_window', function ()

    it('should not crash', function ()
      codetuner:update_window()
      return true
    end)

  end)

  desc('codetuner.render_window', function ()

    it('should not crash', function ()
      codetuner:render_window()
      return true
    end)

  end)

end

add(picotest.test_suite, test_codetuner)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('codetuner', test_codetuner)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
