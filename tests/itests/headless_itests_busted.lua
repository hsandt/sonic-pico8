require("bustedhelper")
require("engine/test/integrationtest")

local function find_all_scripts(dir)
  local files = {}
  local p = io.popen('find "'..dir..'" -type f -name *.lua')
  for file in p:lines() do
    add(files, file)
  end
  return files
end

-- require all itest scripts from the itests folder
-- this will automatically register the itests to the itest_manager
local prefix = 'src/'
local suffix = '.lua'
local itest_scripts = find_all_scripts(prefix..'game/itests')
for itest_script in all(itest_scripts) do
  -- truncate the src path prefix since we require from inside src/
  local require_path = itest_script:sub(prefix:len() + 1, - (suffix:len() + 1))
  require(require_path)
end

-- define a headless unit test for each registered itest so far
for name, itest in pairs(itest_manager.itests) do

  describe(name, function ()

    it('should succeed', function ()
      itest_manager:init_game_and_start_by_name(name)
      while integration_test_runner.current_state == test_states.running do
        integration_test_runner:update_game_and_test()
      end
      assert.are_equal(test_states.success, integration_test_runner.current_state)
    end)

  end)

end
