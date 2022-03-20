local HideNSeek

local function command_handler(name, param)
  local maps = HideNSeek.db.get_all_maps()
  local map_list = {}
  for k in pairs(maps) do
    table.insert(map_list, k)
  end
  table.sort(map_list)
  return true, table.concat(map_list, " ")
end

local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_chatcommand("hs_maps", {
    privs = { hs_admin = true },
    func = command_handler
  })
end

return {
  init = init
}
