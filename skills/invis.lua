local HideNSeek
local invisible_players
local cooldown_by_player_name
local playerphysics = playerphysics

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
    if playerphysics then
      playerphysics.add_physics_factor(player, "speed", "my_double_speed", 2)
    end
  else
    player:set_properties{
      visual_size = {x = 1, y = 1},
    }
    player:set_nametag_attributes({
      color = {a = 255, r = 255, g = 255, b = 255},
    })
    player:set_sky()
    if playerphysics then
      playerphysics.remove_physics_factor(player, "speed", "my_double_speed")
    end
  end

  return true
end

local skill_description = {
  description = "Invis tool",
  inventory_image = "hidenseek_invis_tool.png",
  stack_max = 1,
  cooldown = 3,
  on_use = function(itemstack, player, idk)
    local model = HideNSeek.get_model_by_player(player)

    local player_name = player:get_player_name()
    if invisible_players[player_name] then
      return
    end

    if cooldown_by_player_name[player_name] then
      return
    end

    if not model then
      return
    end

    local model_settings = model:get_settings()
    if model:get_state() ~= model.states.ACTIVE then
      return
    end

    if set_player_invisibility(player, true) then
      model:timer(model_settings.invis_time, function()
        local player_maybe = minetest.get_player_by_name(player_name)
        -- player may've disconnected after item use, we can't rely on old player object
        if player_maybe then
          set_player_invisibility(player_maybe, false)
        end
        cooldown_by_player_name[player_name] = true
        model:timer(model_settings.invis_cooldown, function()
          cooldown_by_player_name[player_name] = nil
        end)
      end)
    end
    return true
  end,
  type = "tool",
  wield_scale = 1,
}

local function init(mod_namespace)
  HideNSeek = mod_namespace
  invisible_players = {}
  cooldown_by_player_name = {}

  HideNSeek.register_skill("hidenseek:invis", skill_description)
end

return {
  init = init,
}
