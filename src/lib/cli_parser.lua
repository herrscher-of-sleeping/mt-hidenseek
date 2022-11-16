local commands = {}

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

local function validate_args(args_desc)
  for i, arg_desc in ipairs(args_desc) do
    local _type = get_type(arg_desc)
    if i ~= #args_desc and _type == "array" then
      error("Vararg can only be at the end of argument list")
    end
  end
end

local function break_line_to_arguments(line)
  local args = {}

  -- body
end


local function execute_command(command_string)

end

local function run_tests()
end

return {
  execute_command = execute_command,
}
