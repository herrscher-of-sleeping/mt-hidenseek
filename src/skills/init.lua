--[[
Skill cooldown display is implemented via tool wear
Skills can have multiple charges which is implemented
by registering N tools. TODO: multiple charges are to be implemented yet
--]]

local MAX_WEAR = 65535

local function find_itemstack_position(inventory, stack)
  local stack_name = "main"
  for i = 1, inventory:get_size(stack_name) do
    local itemstack = inventory:get_stack(stack_name, i)
    if itemstack:get_name() == stack:get_name() then
      return i
    end
  end
  return nil
end

local register_skill = function(name, desc)
  local stack_max = desc.stack_max
  for i = 1, stack_max do
    local tool_desc = {
      inventory_image = desc.inventory_image:gsub("%$", i),
      on_use = function(itemstack, player, pointed_thing)
        local inventory = player:get_inventory()
        local model = HideNSeek.get_model_by_player(player)
        local position = find_itemstack_position(inventory, itemstack)
        local item_name = itemstack:get_name()
        local success, msg = desc.on_use(itemstack, player, pointed_thing)
        if not success then
          if type(msg) == "string" then
            minetest.log("info", msg)
          end
          return
        end
        player:get_inventory():set_stack("main", position, item_name .. " 1 " .. MAX_WEAR)

        model:repeating_timer(1, desc.cooldown, function(count)
          if count == desc.cooldown then
            player:get_inventory():set_stack("main", position, item_name .. " 1")
          else
            local wear = math.floor(MAX_WEAR * (desc.cooldown - count) / desc.cooldown)
            player:get_inventory():set_stack("main", position, item_name .. " 1 " .. wear)
          end
        end)
      end,
      on_drop = function()
        -- pass
      end,
    }

    if stack_max > 1 then
      minetest.unregister_item(name .. "_stack_" .. i)
      minetest.register_tool(name .. "_stack_" .. i, tool_desc)
    else
      minetest.unregister_item(name)
      minetest.register_tool(name, tool_desc)
    end
  end
end

HideNSeek.register_skill = register_skill

require("src/skills/capture").init()
require("src/skills/invis").init()
require("src/skills/search").init()
