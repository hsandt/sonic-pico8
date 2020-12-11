require("test/bustedhelper_titlemenu")
local menu_item = require("menu/menu_item")

describe('menu_item', function ()

  describe('init', function ()
    it('should set label and target state', function ()
      local callback1 = function () end
      local callback2 = function () end

      local item = menu_item("in-game", callback1, callback2)

      assert.are_same({"in-game", callback1, callback2},
        {item.label, item.confirm_callback, item.select_callback})
    end)
  end)

end)
