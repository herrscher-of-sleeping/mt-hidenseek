local argument_parser = require "src/lib/argument_parser"
local commands = {}
HideNSeek.registered_commands = commands

local function get_type(arg_desc)
  local _type = arg_desc[2]
  if _type:sub(1, 1) == "[" then
    _type = "array"
  end
  return _type
end

local function print_usage(message)
  local strings = { message, "Usage: /hs <command>", "Commands:" }
  for cmd_name, cmd_desc in pairs(commands) do
    local line = "hs " .. cmd_name
    local args = {}
    for _, arg_desc in ipairs(cmd_desc.args or {}) do
      local arg_name = arg_desc[1]
      if get_type(arg_desc) == "array" then
        arg_name = arg_name .. "..."
      end
      table.insert(args, arg_name)
    end
    table.insert(strings, line .. " " .. table.concat(args, " "))
  end
  local text = table.concat(strings, "\n")
  return false, text
end


local function command_handler(name, params_string)
  local cmd, raw_params = params_string:match("(.-)[%s+](.+)")
  if not cmd then
    cmd = params_string:match("(%S+)")
  end
  if not cmd then
    return print_usage("No command provided")
  end
  if not commands[cmd] then
    return print_usage(("No command found: %s"):format(cmd))
  end
  local bypass_parsing = commands[cmd].bypass_parsing

  local command_params
  if commands[cmd].bypass_parsing then
    command_params = raw_params
  else
    if not raw_params then
      command_params = {}
    else
      command_params = argument_parser.break_line(raw_params)
      if not command_params then
        return print_usage(("Couldn't break line \"%s\" into parameters"):format(raw_params))
      end
    end
  end
  local ok, ret1, ret2 = pcall(commands[cmd].func, name, command_params)
  local lua_error_occured = not ok
  if lua_error_occured then
    local lua_error = ret1
    minetest.log("error", lua_error)
    return nil, "Lua error occured, see logs"
  end
  local logic_error_occured = not ret1
  if logic_error_occured then
    local logic_error = ret2
    return nil, logic_error
  end
  return ret1, ret2
end

local function register_chatcommand(name, params)
  commands[name] = {
    func = params.func,
    description = params.description,
    params = params.params,
    bypass_parsing = params.bypass_parsing,
  }
end

minetest.register_chatcommand("hs", {
  privs = { hs_admin = true },
  description = "HideNSeek mod commands",
  params = "<subcommand> <subcommand args>",
  func = command_handler,
})
HideNSeek.register_chatcommand = register_chatcommand

require("src/commands/hs_border")
require("src/commands/hs_games")
require("src/commands/hs_maps")
require("src/commands/hs_queue")
require("src/commands/hs_spawn")
require("src/commands/hs_start")
require("src/commands/hs_tp")
require("src/commands/hs_help")
