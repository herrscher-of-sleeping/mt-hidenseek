local HideNSeek

local function init(mod_namespace)
  HideNSeek = mod_namespace

  minetest.register_chatcommand("hs_setspawn", {
    privs = { hs_admin = true },
    func = function(name)
      local pos = minetest.get_player_by_name(name):get_pos()
      HideNSeek.set_spawn_point(pos)
      return true
    end
  })
  minetest.register_chatcommand("hs_spawn", {
    privs = { hs_admin = true },
    func = function(name)
      minetest.get_player_by_name(name):set_pos(HideNSeek.get_spawn_point())
    end
  })
end

return {
  init = init
}
