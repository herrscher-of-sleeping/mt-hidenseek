local function command_handler(name, param)
  local commands = HideNSeek.registered_commands
  local command = param[1]
  if not command then
    return nil, "Usage: /hs help <command>"
  end
  if not commands[command] then
    return nil, "No such command: " .. command
  end
  local text = ("Usage: /hs %s %s\n%s"):format(
    command, commands[command].params or "",
    commands[command].description or ""
  )
  return true, text
end

HideNSeek.register_chatcommand("help", {
  privs = { hs_admin = true },
  description = "Show help about /hs commands",
  func = command_handler
})
