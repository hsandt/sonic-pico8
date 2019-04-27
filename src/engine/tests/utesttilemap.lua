require("engine/test/bustedhelper")
local tilemap = require("engine/data/tilemap")

describe('tilemap', function ()

  describe('_init', function ()
    it('should create a new tilemap with content', function ()
      local tm = tilemap({{1, 2, 3}, {4, 5, 6}})
      assert.is_not_nil(tm)
      assert.are_same({{1, 2, 3}, {4, 5, 6}}, tm.content)
    end)
  end)

  describe('load', function ()
    it('should reset the current map to tile ids stored in content', function ()
      -- initial dirty map to clean
      mset(0, 0, 50)
      local tm = tilemap({{1, 2, 3}, {4, 5, 6}})
      tm:load()
      assert.are_same({1, 2, 3, 4, 5, 6},
        {mget(0, 0), mget(1, 0), mget(2, 0), mget(0, 1), mget(1, 1), mget(2, 1)})
    end)
  end)

  describe('clear_map', function ()

    setup(function ()
      stub(pico8, "clear_map")
    end)

    teardown(function ()
      pico8.clear_map:revert()
    end)

    after_each(function ()
      pico8.clear_map:clear()
    end)

    it('should call clear_map from pico8api (busted only)', function ()
      tilemap.clear_map()
      assert.spy(pico8.clear_map).was_called(1)
      assert.spy(pico8.clear_map).was_called_with(match.ref(pico8))
    end)
  end)

end)
