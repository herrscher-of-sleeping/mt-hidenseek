local M = {}
local storage = minetest.get_mod_storage()
M.storage = storage

function M.add_start_node(map_name, position, direction)
  local maps = minetest.deserialize(storage:get_string("maps")) or {}
  if maps[map_name] then
    return false, "Map already exists"
  end
  maps[map_name] = { position = position, direction = direction }
  storage:set_string("maps", minetest.serialize(maps))
  return true
end

function M.remove_start_node(map_name, position)
  local maps = minetest.deserialize(storage:get_string("maps")) or {}
  maps[map_name] = nil
  storage:set_string("maps", minetest.serialize(maps))
  return true
end

function M.get_map_info(map_name)
  local maps = minetest.deserialize(storage:get_string("maps")) or {}
  return maps[map_name]
end

function M.get_map_position(map_name)
  local maps = minetest.deserialize(storage:get_string("maps")) or {}
  return maps[map_name].position
end

function M.get_all_maps()
  return minetest.deserialize(storage:get_string("maps")) or {}
end

return M
