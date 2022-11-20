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

local function print_usage()
  local strings = { "Usage: /hs <command>", "Commands:" }
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
  local params = argument_parser.break_line(params_string)
  if not params then
    return print_usage()
  end
  local cmd = params[1]
  table.remove(params, 1)
  if not commands[cmd] then
    return print_usage()
  end
  return commands[cmd].handler(name, params or {})
end

local function register_chatcommand(name, params)
  commands[name] = {
    func = params.func,
    description = params.description,
    params = params.params,
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
