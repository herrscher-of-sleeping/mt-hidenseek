local function command_handler(name, param)
  local map_name = param[1]
  if not map_name then
    return nil, "Usage: /hs tp <map_name>"
  end
  local block = HideNSeek.db.get_map_position(map_name)
  if not block then
    return false, "No such map: " .. map_name
  end
  local pos = {
    x = block.x,
    y = block.y + 1,
    z = block.z,
  }
  minetest.get_player_by_name(name):set_pos(pos)
  return true
end

HideNSeek.register_chatcommand("tp", {
  privs = { hs_admin = true },
  description = "Teleport to map",
  params = "<map name>",
  func = command_handler,
})
