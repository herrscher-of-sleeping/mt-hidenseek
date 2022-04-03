local HideNSeek

local inventory_manager = {}

function inventory_manager.backup_player_inventory(player)
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  end
  local inventory = player:get_inventory()
  local inv_list = inventory:get_list("main")
  inventory:set_size("main_backup", inventory:get_size("main"))
  inventory:set_list("main_backup", inv_list)
end

function inventory_manager.restore_player_inventory(player)
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  end
  local inventory = player:get_inventory()
  local inv_list = inventory:get_list("main_backup") or {}
  local is_backup_empty = inventory:is_empty("main_backup")
  if is_backup_empty then
    return
  end
  inventory:set_list("main", inv_list)
  inventory:set_list("main_backup", {})
end


local function try_create_backup_stack_on_join(player)
  local inventory = player:get_inventory()
  local backup_size = inventory:get_size("main_backup")
  if backup_size == 0 then
    inventory:set_size("main_backup", inventory:get_size("main"))
    inventory:set_list("main", { "dummy" })
  end
end

local function try_restore_player_inventory_on_join(player)
  local inventory = player:get_inventory()
  local backup_stack = inventory:get_stack("main_backup", 1):get_name()
  local is_backup_dummy = backup_stack == "dummy"
  if is_backup_dummy then
    return
  end
  local inv_list_backup = inventory:get_list("main_backup")
  inventory:set_list("main", inv_list_backup)
  inventory:set_list("main_backup", { "dummy" })
end

local function on_join(player, last_login)
  try_create_backup_stack_on_join(player)
  try_restore_player_inventory_on_join(player)
end

local function init(mod_namespace, is_reload)
  if is_reload then
    minetest.log("warn", "Can't reload inventory_manager")
    return
  end
  HideNSeek = mod_namespace
  HideNSeek.inventory_manager = inventory_manager
  minetest.register_on_joinplayer(on_join)
end

return {
  init = init
}
