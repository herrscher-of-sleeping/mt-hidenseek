local HideNSeek

local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_chatcommand("hs_dump_maps", {
    privs = { hs_admin = true },
    func = function(name, param)
      return true, "Maps: " .. HideNSeek.db.storage:get_string("maps")
    end,
  })
end

return {
  init = init
}
