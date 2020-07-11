require("engine/test/bustedhelper")
require("data/tile_data")
local tile_test_data = require("test_data/tile_test_data")

describe('tiledata', function ()

  setup(function ()
    stub(tile_test_data, "setup")
    stub(tile_test_data, "teardown")
  end)

  teardown(function ()
    tile_test_data.setup:revert()
    tile_test_data.teardown:revert()
  end)

  after_each(function ()
    tile_test_data.setup:clear()
    tile_test_data.teardown:clear()
  end)

  describe('setup_map_data', function ()
    it('should call setup on tile_test_data (busted only)', function ()
      setup_map_data()
      assert.spy(tile_test_data.setup).was_called(1)
      assert.spy(tile_test_data.setup).was_called_with()
    end)
  end)

  describe('teardown_map_data', function ()
    it('should call teardown on tile_test_data (busted only)', function ()
      teardown_map_data()
      assert.spy(tile_test_data.teardown).was_called(1)
      assert.spy(tile_test_data.teardown).was_called_with()
    end)
  end)

end)
