local function init()
  minetest.register_privilege("hs_admin", {
    description = "Admin commands of HideNSeek mod",
    give_to_singleplayer = true,
  })
end

return {
  init = init
}
