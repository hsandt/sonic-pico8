require("engine/core/helper")

local itest_dsl = {}


-- type of commands available
itest_dsl_command_types = {
  spawn  = 1,
  move   = 2,
  wait   = 11,
  expect = 21
}

-- type of values available for expectations
itest_dsl_value_types = {
  pc_pos = 1
}


-- command struct

-- attributes
-- cmd_type  command_types  type of command invoked
-- args      {*}            sequence of arguments
local command = new_struct()
itest_dsl.command = command

function command:_init(cmd_type, args)
  self.cmd_type = cmd_type
  self.args = args
end


-- dsl itest struct

-- attributes
-- gamestate   string      gamestate to start test in (also the only active gamestate)
-- stage       string|nil  stage to play in if gamestate is 'stage', nil else
-- commands    {commands}  sequence of commands to apply
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
  dsli.gamestate = sub(words[1], 2)
  if dsli.gamestate == "stage" then
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
  return vector(tonum(args[1]), tonum(args[2]))
end

-- convert string args to vector
function itest_dsl.parse_args_move(args)
  assert(#args == 1, "got "..#args.." args")
  return horizontal_dirs[args[1]]
end

-- convert string args to vector
function itest_dsl.parse_args_wait(args)
  assert(#args == 1, "got "..#args.." args")
  return tonum(args[1])  -- frames
end

-- convert string args to vector
function itest_dsl.parse_args_expect(args)
  assert(#args > 1, "got "..#args.." args")
  -- same principle as itest_dsl.parse, the type of the first arg
  --  determines how we parse the rest of the args
  local value_type_str = args[1]
  local expected_value_comps = {}
  for i = 2, #args do
    add(expected_value_comps, args[i])
  end
  local value_type = itest_dsl_value_types[value_type_str]
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
function itest_dsl.create_itest(name, dsli)
  return nil
end


return itest_dsl
