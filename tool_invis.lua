local function init(mod_table)
  local db = mod_table.db
  local timer = mod_table.timer
  local invisible_players = {}
  local cooldown_by_player_name = {}

  local function set_player_invisibility(player, invis_flag)
    local name = player:get_player_name()

    if invisible_players[name] == invis_flag then
      return false
    end

    invisible_players[name] = invis_flag

    if invis_flag then
      player:set_properties{
        visual_size = {x = 0, y = 0},
      }
      player:set_nametag_attributes{
        color = {a = 0, r = 255, g = 255, b = 255},
      }
      player:set_sky({
        base_color = "#000000",
        type = "plain",
      })
    else
      player:set_properties{
        visual_size = {x = 1, y = 1},
      }
      player:set_nametag_attributes({
        color = {a = 255, r = 255, g = 255, b = 255},
      })
      player:set_sky()
    end

    return true
  end

  minetest.register_tool("hidenseek:invis", {
    description = "Invis tool",
    inventory_image = "hidenseek_invis_tool.png",
    stack_max = 1,
    on_use = function(itemstack, player, idk)
      local player_name = player:get_player_name()
      if invisible_players[player_name] then
        return
      end
      if cooldown_by_player_name[player_name] then
        return
      end

      local pos = player:get_pos()
      local model_name, model = mod_table.get_nearest_model(pos)
      local model_settings = model:get_settings()
      if not model then
        return
      end

      minetest.chat_send_all("State: " .. tostring(model:get_state()))
      if model:get_state() ~= model.states.ACTIVE then
        return
      end
      minetest.chat_send_all("test")
      if set_player_invisibility(player, true) then
        timer(model_settings.invis_time, function()
          local player_maybe = minetest.get_player_by_name(player_name)
          -- player may've disconnected after item use, we can't rely on old player object
          if player_maybe then
            set_player_invisibility(player_maybe, false)
          end
          cooldown_by_player_name[player_name] = true
          timer(model_settings.invis_cooldown, function()
            cooldown_by_player_name[player_name] = nil
          end)
        end)
      end
    end,
    type = "tool",
    wield_scale = 1,
  })
end

return {
  init = init,
}