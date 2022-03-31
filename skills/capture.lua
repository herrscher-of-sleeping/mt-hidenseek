local HideNSeek

local tool_description = {
  description = "Capture tool",
  inventory_image = "hidenseek_capture_tool.png",
  stack_max = 1,
  cooldown = 5,
  on_use = function(itemstack, player, pointed_thing)
    local pos = player:get_pos()
    local model = HideNSeek.get_nearest_model(pos)
    if not model then
      return
    end
    if model:get_state() ~= model.states.ACTIVE then
      return
    end
    local hiders = model:get_hiders()
    for _, hider in pairs(hiders) do
      local distance = vector.distance(pos, hider.pos)
      if distance < 2 then
        local ok, msg = model:capture_hider(player:get_player_name(), hider.name)
        if ok then
          minetest.chat_send_all(("Player %s was captured by %s"):format(hider.name, player:get_player_name()))
        end
        if msg then
          minetest.log("info", msg)
        end
      end
    end
    return true
  end,
  type = "tool",
  wield_scale = 1,
}

local function init(mod_namespace)
  HideNSeek = mod_namespace
  HideNSeek.register_skill("hidenseek:capture", tool_description)
end

return {
  init = init,
}
