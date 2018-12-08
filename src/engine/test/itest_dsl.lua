require("engine/core/helper")
local integrationtest = require("engine/test/integrationtest")
local integration_test = integrationtest.integration_test

-- dsl interpretation requirements
local flow = require("engine/application/flow")
local stage = require("game/ingame/stage")  -- required
local pc_data = require("game/data/playercharacter_data")

-- itest dsl parser singleton, with parser context state
-- _itest               integration_test  current integration test in construction
-- _last_time_trigger   time_trigger      last time trigger registered with wait command
local itest_dsl = singleton(function (self)
  self._itest = nil
  self._last_time_trigger = nil
end)


-- type of commands available
itest_dsl_command_types = {
  spawn  = 1,   -- spawn player character        args: {bottom position: vector}
  move   = 2,   -- set sticky pc move intention  args: {move_dir: horizontal_dirs}
  wait   = 11,  --
  expect = 21
}

-- type of values available for expectations
itest_dsl_value_types = {
  pc_pos = 1
}


-- command struct

-- attributes
-- type  command_types  type of command invoked
-- args  {*}            sequence of arguments
local command = new_struct()
itest_dsl.command = command

function command:_init(cmd_type, args)
  self.type = cmd_type
  self.args = args
end


-- dsl itest struct

-- attributes
-- gamestate_type  string      gamestate type to start test in (also the only active gamestate)
-- stage           string|nil  stage to play in if gamestate type is 'stage', nil else
-- commands        {commands}  sequence of commands to apply
local dsl_itest = new_struct()
itest_dsl.dsl_itest = dsl_itest

function dsl_itest:_init()
  -- all attributes are initially nil or empty
  self.commands = {}
end


-- parse a dsl itest source and return a dsl itest
function itest_dsl.parse(dsli_source)
  -- create dsl itest
  local dsli = dsl_itest()

  -- split source lines
  local lines = strspl(dsli_source, '\n', true)

  -- parse first line to get state and optional stage
  local state_line = lines[1]
  assert(sub(state_line, 1, 1) == '@', "state_line '"..state_line.."' doesn't start with @")
  local words = strspl(state_line, ' ', true)
  dsli.gamestate_type = sub(words[1], 2)
  if dsli.gamestate_type == 'stage' then
    assert(#words == 2)
    dsli.stage = words[2]
  end

  for i = 2, #lines do
    words = strspl(lines[i], ' ', true)
    -- if there are no words, the line is empty, so continue
    if #words > 0 then
      local cmd_type_str = words[1]
      local args_str = {}
      for j = 2, #words do
        add(args_str, words[j])
      end
      local cmd_type = itest_dsl_command_types[cmd_type_str]
      local parse_fn_name = 'parse_args_'..cmd_type_str
      assert(itest_dsl[parse_fn_name], "parse function '"..parse_fn_name.."' is not defined")
      local args = {itest_dsl[parse_fn_name](args_str)}
      add(dsli.commands, command(cmd_type, args))
    end
  end
  return dsli
end

-- convert string args to vector
function itest_dsl.parse_args_spawn(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))  -- bottom position
end

-- convert string args to vector
function itest_dsl.parse_args_move(args)
  assert(#args == 1, "got "..#args.." args")
  return horizontal_dirs[args[1]]                -- move intention
end

-- convert string args to vector
function itest_dsl.parse_args_wait(args)
  assert(#args == 1, "got "..#args.." args")
  return tonum(args[1])                          -- frames to wait
end

-- convert string args to vector
function itest_dsl.parse_args_expect(args)
  assert(#args > 1, "got "..#args.." args")
  -- same principle as itest_dsl.parse, the type of the first arg
  --  determines how we parse the rest of the args, named "value components"
  local value_type_str = args[1]
  -- gather all the value components as strings (e.g. {"3", "4"} for vector(3, 4))
  local expected_value_comps = {}
  for i = 2, #args do
    add(expected_value_comps, args[i])
  end
  -- determine the type of value reference tested for comparison (e.g. pc position)
  local value_type = itest_dsl_value_types[value_type_str]
  -- parse the value components to semantical type (e.g. vector)
  local parse_fn_name = 'parse_value_'..value_type_str
  assert(itest_dsl[parse_fn_name], "parse function '"..parse_fn_name.."' is not defined")
  local expected_value = itest_dsl[parse_fn_name](expected_value_comps)
  return value_type, expected_value
end

-- convert string args to vector
function itest_dsl.parse_value_pc_pos(args)
  assert(#args == 2, "got "..#args.." args")
  return vector(tonum(args[1]), tonum(args[2]))
end

-- create and return an itest from a dsli, providing a name
function itest_dsl:create_itest(name, dsli)
  self._itest = integration_test(name, {dsli.gamestate_type})
  self._itest.setup = function ()
    flow:change_gamestate_by_type(dsli.gamestate_type)
    if dsli.gamestate_type == "stage" then
      assert(dsli.stage)
      -- load stage by name when api is ready
    end
  end

  for cmd in all(dsli.commands) do
    print(cmd.type)
    if cmd.type == itest_dsl_command_types.spawn then
      print(dump(self._itest))
      self:_act(function ()
        stage.state.player_char:spawn_at(vector(cmd.args[1].x, cmd.args[1].y - pc_data.center_height_standing))
      end)
      print(dump(self._itest))
    elseif cmd.type == itest_dsl_command_types.move then
      print(dump(self._itest))
      self:_act(function ()
        stage.state.player_char.move_intention = horizontal_dir_vectors[cmd.args[1]]
      end)
    elseif cmd.type == itest_dsl_command_types.wait then
      print("wait")
      self:_wait(cmd.args[1])
    elseif cmd.type == itest_dsl_command_types.expect then
      print("expect")
      -- we currently don't support live assertions, only final assertion
      self:_final_assert(unpack(cmd.args))

    end
  end

  -- if we finished with a wait (with or without final assertion),
  --  we need to close the itest with a wait-action
  if self._last_time_trigger then
    print("final")
    self._itest:add_action(self._last_time_trigger, nil)
  end

  local test = self._itest

  -- cleanup
  self._itest = nil
  self._last_time_trigger = nil

  return test
end

function itest_dsl:_act(callback)
  if self._last_time_trigger then
    self._itest:add_action(self._last_time_trigger, callback)
    self._last_time_trigger = nil  -- consume so we know no final wait-action is needed
  else
    -- no wait since last action (or this is the first action), so use immediate trigger
    self._itest:add_action(integrationtest.immediate_trigger, callback)
  end
end

function itest_dsl:_wait(interval)
  if self._last_time_trigger then
    -- we were already waiting, so finish last wait with empty action
    self._itest:add_action(self._last_time_trigger, nil)
  end
  -- we only support frame unit in the dsl
  self._last_time_trigger = integrationtest.time_trigger(interval, true)
  print("set wait")
end

function itest_dsl:_final_assert(gameplay_value_type, expected_gameplay_value)
  self._itest.final_assertion = function ()
    return self._evaluate(gameplay_value_type) == expected_gameplay_value
  end
end

-- evaluate gameplay value. it is important to call this at expect
--  time, not when defining the test, to get the actual runtime value
function itest_dsl._evaluate(gameplay_value_type)
  if gameplay_value_type == itest_dsl_value_types.pc_pos then
    return stage.state.player_char.position
  else
    assert(false, "unknown gameplay value: "..gameplay_value_type)
  end
end

return itest_dsl
