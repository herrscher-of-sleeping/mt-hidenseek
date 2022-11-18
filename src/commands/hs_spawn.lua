--[[
Special place serving as game lobby possibly?
--]]

HideNSeek.register_chatcommand("setspawn", {
  privs = { hs_admin = true },
  description = "Set spawn point for HideNSeek mod",
  func = function(name)
    local pos = minetest.get_player_by_name(name):get_pos()
    HideNSeek.set_spawn_point(pos)
    return true
  end
})

HideNSeek.register_chatcommand("spawn", {
  privs = { hs_admin = true },
  description = "Teleport to HideNSeek mod's spawn point",
  func = function(name)
    minetest.get_player_by_name(name):set_pos(HideNSeek.get_spawn_point())
  end
})
