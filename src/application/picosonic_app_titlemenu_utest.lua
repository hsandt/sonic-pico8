require("test/bustedhelper_titlemenu")
local picosonic_app_titlemenu = require("application/picosonic_app_titlemenu")

local titlemenu = require("menu/titlemenu")
local credits = require("menu/credits")

describe('picosonic_app_titlemenu', function ()

  local app

  before_each(function ()
    app = picosonic_app_titlemenu()
  end)

  describe('instantiate_gamestates', function ()

    it('should return all gamestates', function ()
      assert.are_same({titlemenu(), credits()}, picosonic_app_titlemenu:instantiate_gamestates())
    end)

  end)

end)
