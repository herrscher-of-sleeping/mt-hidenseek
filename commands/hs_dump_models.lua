local HideNSeek

local function command_handler(name, param)
  local models = HideNSeek.get_models()
  local model_names = {}
  for model_name, model in pairs(models) do
    local state = model:get_state()
    table.insert(model_names, model_name .. "(" .. state .. ")")
  end
  return true, "Models: " .. table.concat(model_names, ", ")
end

local function init(mod_namespace)
  HideNSeek = mod_namespace

  minetest.register_chatcommand("hs_dump_models", {
    privs = { hs_admin = true },
    func = command_handler,
  })
end

return {
  init = init
}
