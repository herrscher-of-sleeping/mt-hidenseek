local HideNSeek

local function init(mod_namespace)
  HideNSeek = mod_namespace

  minetest.register_chatcommand("hs_queue_me", {
    privs = {},
    description = "Create map borders at current position",
    params = "(circle <radius> <height>) | (rm <radius> <height>)",
    func = function(name)
      minetest.get_player_by_name(name):set_pos(HideNSeek.get_spawn_point())
    end
  })
end

return {
  init = init
}
