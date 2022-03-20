local HideNSeek

local BORDER_NODE_NAME = "hidenseek:border"

-- TODO: use Lua Voxel Manipulator

local function safe_set_border_node(pos)
  local node = minetest.get_node(pos)
  if node.name == "air" then
    minetest.set_node(pos, { name = BORDER_NODE_NAME } )
  end
end

local function safe_unset_border_node(pos)
  local node = minetest.get_node(pos)
  if node.name == BORDER_NODE_NAME then
    minetest.set_node(pos, { name = "air" } )
  end
end

local function make_column(x, y, z, h)
  for i = 0, h - 1 do
    local pos = { x = x, y = y + i, z = z }
    safe_set_border_node(pos)
  end
end

local function add_wall(pos, radius, height)
  local x = radius
  local z = 0

  make_column(pos.x + radius, pos.y, pos.z, height)
  make_column(pos.x - radius, pos.y, pos.z, height)
  make_column(pos.x, pos.y, pos.z + radius, height)
  make_column(pos.x, pos.y, pos.z - radius, height)

  local p = 1 - radius
  while x > z do
    z = z + 1
    if p <= 0 then
      p = p + 2 * z + 1
    else
      x = x - 1
      p = p + 2 * z - 2 * x + 1
    end

    if x < z then
      break
    end

    make_column(x + pos.x, pos.y, z + pos.z, height)
    make_column(-x + pos.x, pos.y, z + pos.z, height)
    make_column(x + pos.x, pos.y, -z + pos.z, height)
    make_column(-x + pos.x, pos.y, -z + pos.z, height)

    if x ~= z then
      make_column(z + pos.x, pos.y, x + pos.z, height)
      make_column(-z + pos.x, pos.y, x + pos.z, height)
      make_column(z + pos.x, pos.y, -x + pos.z, height)
      make_column(-z + pos.x, pos.y, -x + pos.z, height)
    end
  end
  return true
end

local function remove_wall(pos, radius, height)
  for x = pos.x - radius, pos.x + radius do
    for z = pos.z - radius, pos.z + radius do
      for y = pos.y, pos.y + height do
        safe_unset_border_node({ x = x, y = y, z = z })
      end
    end
  end
end

local function command_handler(name, command)
  local params = HideNSeek.util.split_string(command)
  local pos = minetest.get_player_by_name(name):get_pos()
  pos.x = math.round(pos.x)
  pos.y = math.round(pos.y)
  pos.z = math.round(pos.z)
  local subcmd = params[1]
  if subcmd ~= "circle" and subcmd ~= "rm" then
    return false, "Unknown subcommand: " .. subcmd
  end
  local radius = tonumber(params[2])
  local height = tonumber(params[3])
  local is_force = params[4] == "force"

  if not radius or radius <= 0 then
    return false, "Radius should be integer > 0"
  end
  if not height or height <= 0 then
    return false, "Height should be integer > 0"
  end
  if not is_force then
    if radius > 50 then
      return false, "Radius shouldn't be > 50"
    end
    if height > 50 then
      return false, "Height shouldn't be > 50"
    end
  end

  if subcmd == "circle" then
    add_wall(pos, radius, height)
  elseif subcmd == "rm" then
    remove_wall(pos, radius, height)
  end
  return true
end

local function init(mod_namespace, is_reload)
  HideNSeek = mod_namespace
  if is_reload then
    minetest.chat_send_all("Reload")
    minetest.unregister_chatcommand("hs_border")
  end
  minetest.register_chatcommand("hs_border", {
    privs = { hs_admin = true },
    description = "Create map borders at current position",
    params = "(circle <radius> <height>) | (rm <radius> <height>)",
    func = command_handler,
  })
end

return {
  init = init
}
