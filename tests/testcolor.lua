require("bustedhelper")
require("engine/render/color")

describe('color_tostring', function ()

  it('should return the name of a known color by index', function ()
    assert.are_equal("dark_purple", color_tostring(2))
  end)

  it('should return the name of a known color by enum', function ()
    assert.are_equal("pink", color_tostring(colors.pink))
  end)

  it('should return "unknown color" for nil', function ()
    assert.are_equal("unknown color", color_tostring(nil))
  end)

  it('should return "unknown color" for -1', function ()
    assert.are_equal("unknown color", color_tostring(-1))
  end)

  it('should return "unknown color" for 16', function ()
    assert.are_equal("unknown color", color_tostring(16))
  end)

  it('should return "unknown color" for a table', function ()
    assert.are_equal("unknown color", color_tostring({}))
  end)

end)
