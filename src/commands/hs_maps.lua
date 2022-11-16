local function command_handler(name, param)
  local maps = HideNSeek.db.get_all_maps()
  local map_list = {}
  for k in pairs(maps) do
    table.insert(map_list, k)
  end
  table.sort(map_list)
  return true, table.concat(map_list, " ")
end

HideNSeek.register_chatcommand("maps", {
  privs = { hs_admin = true },
  description = "List maps",
  handler = command_handler
})
