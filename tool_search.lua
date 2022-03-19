local function init(mod_table)
  local timer = mod_table.timer
  local db = mod_table.db
  local search_lock_by_player = {}

  minetest.register_tool("hidenseek:search", {
    description = "Search tool",
    inventory_image = "hidenseek_capture_tool.png",
    stack_max = 1,
    on_use = function(itemstack, player, pointed_thing)
      local player_name = player:get_player_name()
      local pos = player:get_pos()
      local model_name, model = mod_table.get_nearest_model(pos)
      if not model then
        return
      end
      local model_settings = model:get_settings()
      if not model_settings then
        return
      end
      minetest.chat_send_all("model_settings: " .. tostring(model_settings))
      local particle_pos = player:get_pos()
      local view_dir = player:get_look_dir()
      view_dir.y = 0
      view_dir = vector.normalize(view_dir)
      particle_pos.y = particle_pos.y + 1
      particle_pos = particle_pos + view_dir
      minetest.add_particle({
        pos = particle_pos,
        velocity = view_dir,
        acceleration = vector.multiply(view_dir, 5),
        expirationtime = 3,
	      size = 1,
	      glow = minetest.LIGHT_MAX,
        collisiondetection = false,
        vertical = false,
        texture = "hidenseek_search_particle.png",
      })

      timer(model_settings.search_tool_cooldown, function()
        -- model.tool_locks[player_name] = nil
      end)
    end,
    on_drop = function(itemstack, player, pos)
      minetest.chat_send_all("Dropping this is illegal!!! This incident will be reported!! And you will go to jail!!")
    end,
    type = "tool",
    wield_scale = 1,
  })
end

return {
  init = init,
}
