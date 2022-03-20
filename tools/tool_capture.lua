local HideNSeek

local tool_description = {
  description = "Capture tool",
  inventory_image = "hidenseek_capture_tool.png",
  stack_max = 1,
  on_use = function(itemstack, player, pointed_thing)
    local pos = player:get_pos()
    local model_name, model = HideNSeek.get_nearest_model(pos)
    if not model then
      return
    end
    if model:get_state() ~= model.states.ACTIVE then
      return
    end
    minetest.chat_send_all("Nearest model: " .. tostring(model_name))
    local hiders = model:get_hiders()
    for _, hider in pairs(hiders) do
      minetest.chat_send_all(("Player %s is found at pos %f,%f,%f"):format(
        hider.name, hider.pos.x, hider.pos.y, hider.pos.z
      ))
      local distance = vector.distance(pos, hider.pos)
      if distance < 2 then
        local ok, msg = model:capture_hider(player:get_player_name(), hider.name)
        if msg then
          minetest.chat_send_all(msg)
        end
      end
    end
  end,
  on_drop = function(itemstack, player, pos)
    minetest.chat_send_all("Dropping this is illegal!!! This incident will be reported!!")
  end,
  type = "tool",
  wield_scale = 1,
}

local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_tool("hidenseek:capture", tool_description)
end

return {
  init = init,
}
