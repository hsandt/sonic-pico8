require("test/bustedhelper_titlemenu")
local menu = require("menu/menu")
local menu_with_sfx = require("menu/menu_with_sfx")

local menu_item = require("menu/menu_item")
local audio = require("resources/audio")

describe('menu_with_sfx', function ()

  local fake_app = {}

  describe('(with instance, stubbing sfx)', function ()

    local m

    setup(function ()
      stub(_G, "sfx")
    end)

    teardown(function ()
      sfx:revert()
    end)

    before_each(function ()
      m = menu_with_sfx(fake_app, 2, alignments.left, colors.red)
    end)

    after_each(function ()
      sfx:clear()
    end)

    describe('on_selection_changed', function ()

      it('should play selection sfx', function ()
        menu_with_sfx.on_selection_changed()

        local s = assert.spy(sfx)
        s.was_called(1)
        s.was_called_with(audio.sfx_ids.menu_select)
      end)

    end)

    describe('on_confirm_selection', function ()

      it('should play selection sfx', function ()
        menu_with_sfx.on_confirm_selection()

        local s = assert.spy(sfx)
        s.was_called(1)
        s.was_called_with(audio.sfx_ids.menu_confirm)
      end)

    end)

  end)  -- (with instance)

end)
