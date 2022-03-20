local HideNSeek

local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_chatcommand("hs_reload", {
    privs = { hs_admin = true },
    func = function(name, command)
      local module_name = command
      return HideNSeek.reload_module(module_name)
    end
  })
end

return {
  init = init
}
