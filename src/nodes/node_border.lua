local function init()
  minetest.register_node("hidenseek:border", {
    description = "Glasslike Framed Drawtype Border Node",
    drawtype = "glasslike",
    paramtype = "light",
    use_texture_alpha = true,
    light_source = 7,
    tiles = {
      {
        name = "hidenseek_field_animated.png",
        animation = {
          type = "vertical_frames",
          aspect_w = 32,
          aspect_h = 32,
          length = 4,
        }
      }
    },

    sunlight_propagates = true,
    groups = { dig_immediate = 3 },
  })
end

return {
  init = init,
}
