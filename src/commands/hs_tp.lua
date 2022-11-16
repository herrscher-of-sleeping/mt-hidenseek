local function command_handler(name, param)
  local block = HideNSeek.db.get_map_position(param)
  if not block then
    return false, "No such map: " .. param
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
  handler = command_handler,
})
