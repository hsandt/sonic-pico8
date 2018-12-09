require("bustedhelper")
local tilemap = require("engine/data/tilemap")

describe('tilemap', function ()

  describe('_init', function ()
    it('should create a new tilemap with content', function ()
      local tm = tilemap({{1, 2, 3}, {4, 5, 6}})
      assert.is_not_nil(tm)
      assert.are_same({{1, 2, 3}, {4, 5, 6}}, tm.content)
    end)
  end)

end)
