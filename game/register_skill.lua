local HideNSeek

local MAX_WEAR = 65535

--[[ *** Stack search ***
local inventory = minetest.get_player_by_name("singleplayer"):get_inventory()

local stack = inventory:get_stack("main", 6)
local mt = getmetatable(stack)
for k, v in pairs(mt) do
  print(k, v)
end
print(stack)
--stack:replace("mcl_tools:axe_wood 1 10000")
print(stack:to_string())
for i = 1,  inventory:get_size("main") do
  local itemstack = inventory:get_stack("main", i)
  if itemstack:to_string() == stack:to_string() then
    print("found at " .. i)
  end
end
--]]

local function find_itemstack_position(inventory)
end

local register_skill = function(name, desc)
  local stack_max = desc.stack_max
  for i = 1, stack_max do
    local tool_desc = {
      inventory_image = desc.inventory_image:gsub("%$", i),
      on_use = function(itemstack, player, pointed_thing)
        local model = HideNSeek.get_model_by_player(player)
        model:multitimer(1, desc.cooldown, function(count)
          if count == desc.cooldown then
            player:get_inventory():get_stack("main", 1, "TODO")
          else
            local wear = math.floor(MAX_WEAR * (desc.cooldown - count) / desc.cooldown)
            player:get_inventory():get_stack("main", 1, "TODO" .. wear)
          end
        end)
      end
    }

    minetest.register_tool(name .. "_stack_" .. i, tool_desc)
  end
  return minetest.register_tool(name, desc)
end

local function init(mod_namespace)
  HideNSeek = mod_namespace
  HideNSeek.register_skill = register_skill
end

-- example
HideNSeek.register_skill("invis", {
  stack_max = 3,
  cooldown = 10,
  on_use = function(player)
    minetest.chat_send_all(player:get_player_name() .. " used tool invis")
  end
})

return {
  init = init
}
