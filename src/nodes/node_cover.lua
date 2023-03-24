local function init()
  minetest.register_node("hidenseek:cover", {
    description = "Cell to keep seeker before the game starts",
    tiles = { "hidenseek_cover.png" },
  })
end

return {
  init = init,
}
