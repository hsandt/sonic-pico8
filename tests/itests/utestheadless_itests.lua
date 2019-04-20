require("bustedhelper")
require("engine/test/integrationtest")
local gameapp = require("game/application/gameapp")
local gamestate_proxy = require("game/application/gamestate_proxy")

-- check options
local should_render = false
if contains(arg, "--render") then
  should_render = true
end

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

describe('headless itest', function ()

  after_each(function ()
    gameapp.reinit_modules()
  end)

  -- define a headless unit test for each registered itest so far
  for i = 1, #itest_manager.itests do

    local itest = itest_manager.itests[i]

    it(itest.name..' should succeed', function ()

      itest_manager:init_game_and_start_by_index(i)
      while itest_runner.current_state == test_states.running do
        itest_runner:update_game_and_test()
        if should_render then
          itest_runner:draw_game_and_test()
        end
      end

      local itest_fail_message = nil
      if itest_runner.current_message then
        itest_fail_message = "itest '"..itest.name.."' ended with "..itest_runner.current_state.." due to:\n"..itest_runner.current_message
      end

      assert.are_equal(test_states.success, itest_runner.current_state, itest_fail_message)

    end)

  end

end)
