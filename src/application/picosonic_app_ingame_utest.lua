require("test/bustedhelper")
local picosonic_app_ingame = require("application/picosonic_app_ingame")

local stage_state = require("ingame/stage_state")

describe('picosonic_app_ingame', function ()

  local app

  before_each(function ()
    app = picosonic_app_ingame()
  end)

  describe('instantiate_gamestates', function ()

    it('should return all gamestates', function ()
      assert.are_same({stage_state()}, picosonic_app_ingame:instantiate_gamestates())
    end)

  end)

end)
