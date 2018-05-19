local picotest = require("picotest")
local profiler = require("profiler")

function test_profiler(desc,it)

  desc('profiler.lazy_init', function ()

    profiler:lazy_init()

    it('should initialize the profiler with stat labels and correct values', function ()
      return profiler.initialized,
      profiler.stat_overlay.labels["memory"] ~= nil,
      profiler.stat_overlay.labels["memory (value)"] ~= nil,
      profiler.stat_overlay.labels["total cpu"] ~= nil,
      profiler.stat_overlay.labels["total cpu (value)"] ~= nil,
      profiler.stat_overlay.labels["system cpu"] ~= nil,
      profiler.stat_overlay.labels["system cpu (value)"] ~= nil,
      profiler.stat_overlay.labels["fps"] ~= nil,
      profiler.stat_overlay.labels["fps (value)"] ~= nil,
      profiler.stat_overlay.labels["target fps"] ~= nil,
      profiler.stat_overlay.labels["target fps (value)"] ~= nil,
      profiler.stat_overlay.labels["actual fps"] ~= nil,
      profiler.stat_overlay.labels["actual fps (value)"] ~= nil
    end)

    profiler.initialized = false
    clear_table(profiler.stat_overlay.labels)

  end)

  desc('profiler.update_stats', function ()

    profiler:lazy_init()

    -- hard to test that stats were correctly updated
    -- because cpu will change between 2 calls of stat()
    it('should not crash if already initialized', function ()
      profiler:update_stats()
      return true
    end)

    profiler.initialized = false
    clear_table(profiler.stat_overlay.labels)

  end)

  desc('profiler.render', function ()

    profiler:render()

    it('should lazy init if not already initialized"', function ()
      return profiler.initialized,
        profiler.stat_overlay.labels["memory"] ~= nil,
        profiler.stat_overlay.labels["memory (value)"] ~= nil,
        profiler.stat_overlay.labels["total cpu"] ~= nil,
        profiler.stat_overlay.labels["total cpu (value)"] ~= nil,
        profiler.stat_overlay.labels["system cpu"] ~= nil,
        profiler.stat_overlay.labels["system cpu (value)"] ~= nil,
        profiler.stat_overlay.labels["fps"] ~= nil,
        profiler.stat_overlay.labels["fps (value)"] ~= nil,
        profiler.stat_overlay.labels["target fps"] ~= nil,
        profiler.stat_overlay.labels["target fps (value)"] ~= nil,
        profiler.stat_overlay.labels["actual fps"] ~= nil,
        profiler.stat_overlay.labels["actual fps (value)"] ~= nil
    end)

    profiler:render()

    -- hard to test that stats were correctly updated
    -- because cpu will change between 2 calls of stat()
    it('should preserve labels if already initialized"', function ()
      return profiler.initialized,
        profiler.stat_overlay.labels["memory"] ~= nil,
        profiler.stat_overlay.labels["memory (value)"] ~= nil,
        profiler.stat_overlay.labels["total cpu"] ~= nil,
        profiler.stat_overlay.labels["total cpu (value)"] ~= nil,
        profiler.stat_overlay.labels["system cpu"] ~= nil,
        profiler.stat_overlay.labels["system cpu (value)"] ~= nil,
        profiler.stat_overlay.labels["fps"] ~= nil,
        profiler.stat_overlay.labels["fps (value)"] ~= nil,
        profiler.stat_overlay.labels["target fps"] ~= nil,
        profiler.stat_overlay.labels["target fps (value)"] ~= nil,
        profiler.stat_overlay.labels["actual fps"] ~= nil,
        profiler.stat_overlay.labels["actual fps (value)"] ~= nil
    end)

    profiler.initialized = false
    clear_table(profiler.stat_overlay.labels)

  end)

end

add(picotest.test_suite, test_profiler)


-- pico-8 functions must be placed at the end to be parsed by p8tool

function _init()
  picotest.test('profiler', test_profiler)
end

-- empty update allows to close test window with ctrl+c
function _update()
end
