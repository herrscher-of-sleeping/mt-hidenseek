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
      for y = pos.y - height, pos.y + height do
        safe_unset_border_node({ x = x, y = y, z = z })
      end
    end
  end
  return true
end

local subcommands = {}

local function get_rounded_player_position(name)
  local pos = minetest.get_player_by_name(name):get_pos()
  pos.x = math.round(pos.x)
  pos.y = math.round(pos.y)
  pos.z = math.round(pos.z)
  return pos
end

subcommands.circle = function(name, params)
  local radius = tonumber(params[1])
  local height = tonumber(params[2])
  local is_force = params[3] == "force"
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

  local pos = get_rounded_player_position(name)
  return add_wall(pos, radius, height)
end

subcommands.rm = function(name, params)
  local radius = tonumber(params[1])
  local height = tonumber(params[2])
  local is_force = params[3] == "force"
  if not radius or radius <= 0 then
    return false, "Radius should be integer > 0"
  end
  if params[2] == "force" then
    height = radius
    is_force = true
  end
  if not height then height = radius; end
  if not radius or radius <= 0 then
    return false, "Radius should be integer > 0"
  end
  if height and height <= 0 then
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

  local pos = get_rounded_player_position(name)
  return remove_wall(pos, radius, height or radius)
end

local function command_handler(name, command)
  local params = HideNSeek.util.split_string(command)

  local subcmd = params[1]

  if not subcommands[subcmd] then
    return false, "Unknown subcommand: " .. subcmd
  end

  table.remove(params, 1)
  return subcommands[subcmd](name, params)
end

HideNSeek.register_chatcommand("border", {
  privs = { hs_admin = true },
  description = "Create map borders at current position",
  params = "(circle <radius> <height>) | (rm <radius> <height>)",
  func = command_handler,
})
