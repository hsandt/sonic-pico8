require("engine/test/bustedhelper")
local codetuner = require("engine/debug/codetuner")

describe('codetuner', function ()

  describe('position utils', function ()

    -- simulate widget child with position and size via duck-typing
    local mock_widget = {x = 5, y = 6, w = 8, h = 9}

    describe('next_to', function ()

      it('should return a new position on the right of a widget with a default margin of 2', function ()
        assert.are_same({15, 6}, {codetuner.next_to(mock_widget)})
      end)

      it('should return a new position on the right of a widget with the passed margin', function ()
        assert.are_same({17, 6}, {codetuner.next_to(mock_widget, 4)})
      end)

    end)

    describe('below', function ()

      it('should return a new position below a widget with a default margin of 2', function ()
        assert.are_same({5, 17}, {codetuner.below(mock_widget)})
      end)

      it('should return a new position below a widget with the passed margin', function ()
        assert.are_same({5, 19}, {codetuner.below(mock_widget, 4)})
      end)

    end)

  end)

  describe('tuned_variable', function ()

    describe('_init', function ()
      it('should create a new tile vector with the right coordinates', function ()
        local tuned_var = codetuner.tuned_variable("offset", 6)
        assert.are_same({"offset", 6}, {tuned_var.name, tuned_var.default_value})
      end)
    end)

    describe('_tostring', function ()
      it('should return a string representation with the name and default value', function ()
        local tuned_var = codetuner.tuned_variable("offset", 6)
        assert.are_equal("tuned_variable \"offset\" (default: 6)", tuned_var:_tostring())
      end)
    end)

  end)

  describe('(codetuner active)', function ()
    local warn_stub

    setup(function ()
      codetuner.active = true  -- needed to create tuned vars
      warn_stub = stub(_G, "warn")
    end)

    teardown(function ()
      codetuner.active = false
      warn_stub:revert()
    end)

    after_each(function ()
      clear_table(codetuner.tuned_vars)
      clear_table(codetuner.main_panel.children)
      warn_stub:clear()
    end)

    describe('get_spinner_callback', function ()

      it('should return a function that sets an existing tuned var', function ()
        tuned("tuned_var", 17)
        local f = codetuner:get_spinner_callback("tuned_var")
        -- simulate spinner via duck-typing
        local fake_spinnner = {value = 11}
        f(fake_spinnner)
        assert.are_equal(11, codetuner.tuned_vars["tuned_var"])
      end)

    end)

    describe('get_or_create_tuned_var', function ()

      it('when name doesn\'t exist it should create tuned var with default value and return it', function ()
        local result = tuned("unknown", 14)
        assert.are_same({14, 14}, {codetuner.tuned_vars["unknown"], result})
      end)

      it('when name exists it should return the current tuned value', function ()
        tuned("tuned_var", 20)
        -- we normally avoid conflicting default values,
        -- but this example is to show we use the actual current value
        local tuned_var_before_set = tuned("tuned_var", -20)
        codetuner:set_tuned_var("tuned_var", 170)
        local tuned_var_after_set = tuned("tuned_var", -25)
        assert.are_same({20, 170}, {tuned_var_before_set, tuned_var_after_set})
      end)

      it('should add corresponding children to the panel', function ()
        tuned("tuned_var1", 1)
        tuned("tuned_var2", 2)
        assert.is_not_nil(codetuner.main_panel)
        assert.are_equal(2, #codetuner.main_panel.children)
      end)

    end)

    describe('set_tuned_var', function ()

      it('should set tuned value if it exists', function ()
        tuned("tuned_var", 24)
        codetuner:set_tuned_var("tuned_var", 26)
        assert.are_equal(26, codetuner.tuned_vars["tuned_var"])
      end)

      it('should do nothing if the passed tuned var doesn\'t exist', function ()
        codetuner:set_tuned_var("unknown", 28)
        assert.is_nil(codetuner.tuned_vars["unknown"])
        assert.spy(warn_stub).was_called(1)
        assert.spy(warn_stub).was_called_with(match.matches('codetuner:set_tuned_var: no tuned var found with name: .*'), "codetuner")
      end)

    end)

  end)

  describe('(codetuner inactive)', function ()

    after_each(function ()
      clear_table(codetuner.tuned_vars)
      clear_table(codetuner.main_panel.children)
    end)

    describe('get_or_create_tuned_var', function ()

      it('should not create a new tuned var, not return any existing tuned var and return default value', function ()
        -- avoid conflicting default values, but this example is to show we use the passed one
        codetuner.active = false
        local inactive_tuned_var_before_set = tuned("tuned_var", 12)
        local inactive_tuned_var_after_set = tuned("tuned_var", 18)
        -- if a new default is provided, it is used whatever
        assert.is_nil(codetuner.tuned_vars["tuned var"])
        assert.are_same({inactive_tuned_var_before_set, inactive_tuned_var_after_set},
          {12, 18})
      end)
    end)

  end)

  describe('(gui invisible)', function ()

    before_each(function ()
      codetuner.gui.visible = false
    end)

    after_each(function ()
      codetuner.gui.visible = false
    end)

    describe('show', function ()

      it('should make the gui visible', function ()
        codetuner:show()
        assert.is_true(codetuner.gui.visible)
      end)

    end)

    describe('hide', function ()

      it('should make the gui invisible', function ()
        codetuner.gui.visible = true
        codetuner:hide()
        assert.is_false(codetuner.gui.visible)
      end)

    end)

  end)

  describe('(on start) codetuner:init_window', function ()

    it('should have constructed a gui root with a panel of tuned values', function ()
      assert.is_not_nil(codetuner.gui)
      assert.is_false(codetuner.gui.visible)
      assert.are_equal(1, #codetuner.gui.children)
      assert.are_equal(codetuner.main_panel, codetuner.gui.children[1])
    end)

  end)

  describe('codetuner:update_window', function ()
    local update_stub

    setup(function ()
      update_stub = stub(codetuner.gui, "update")
    end)

    teardown(function ()
      update_stub:revert()
    end)

    it('should call gui:update', function ()
      codetuner:update_window()
      assert.spy(update_stub).was_called()
      assert.spy(update_stub).was_called_with(match.ref(codetuner.gui))
    end)

  end)

  describe('codetuner:render_window', function ()
    local draw_stub

    setup(function ()
      draw_stub = stub(codetuner.gui, "draw")
    end)

    teardown(function ()
      draw_stub:revert()
    end)

    it('should call gui:draw', function ()
      codetuner:render_window()
      assert.spy(draw_stub).was_called()
      assert.spy(draw_stub).was_called_with(match.ref(codetuner.gui))
    end)

  end)

end)
