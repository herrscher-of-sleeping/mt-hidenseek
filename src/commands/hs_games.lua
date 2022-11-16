local function command_handler(name, param)
  local models = HideNSeek.get_models()
  local model_names = {}
  for model_name, model in pairs(models) do
    local state = model:get_state()
    table.insert(model_names, model_name .. "(" .. state .. ")")
  end
  return true, "Game states for maps: " .. table.concat(model_names, ", ")
end

HideNSeek.register_chatcommand("games", {
  privs = { hs_admin = true },
  description = "Print states of running game instances",
  handler = command_handler,
})

