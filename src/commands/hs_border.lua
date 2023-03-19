-- TODO: convert /hs border circle into using set points, probably rename it to ellipse
-- TODO: use Lua Voxel Manipulator (maybe?)

local BORDER_NODE_NAME = "hidenseek:border"

local points = {}

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

local function add_ring_wall(pos, radius, height)
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

local function add_rect_wall(point1, point2)
  local x0 = math.min(point1.x, point2.x)
  local x1 = math.max(point1.x, point2.x)
  local z0 = math.min(point1.z, point2.z)
  local z1 = math.max(point1.z, point2.z)
  -- Remember that y is vertical axis in Minetest
  local y0 = math.min(point1.y, point2.y)
  local y1 = math.max(point1.y, point2.y)
  local height = y1 - y0

  for x = x0, x1 do
    make_column(x, y0, z0, height)
    make_column(x, y0, z1, height)
  end
  for z = z0 + 1, z1 - 1 do
    make_column(x0, y0, z, height)
    make_column(x1, y0, z, height)
  end
end

local function remove_wall(point1, point2)

  for x = math.min(point1.x, point2.x), math.max(point1.x, point2.x) do
    for z = math.min(point1.z, point2.z), math.max(point1.z, point2.z) do
      for y = math.min(point1.y, point2.y), math.max(point1.y, point2.y) do
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
  return add_ring_wall(pos, radius, height)
end

subcommands.rect = function(name, params)
  local point1 = points[1]
  local point2 = points[2]
  if not point1 or not point2 then
    return nil, "Set points first using /hs border set_point 1/2"
  end
  return add_rect_wall(point1, point2)
end

subcommands.set_point = function(name, params)
  local pos = get_rounded_player_position(name)
  local point_num = tonumber(params[1])
  points[point_num] = pos
  return true
end

subcommands.rm = function(name, params)
  local point1 = points[1]
  local point2 = points[2]
  return remove_wall(point1, point2)
end

local function command_handler(name, params)
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
  params = "(circle <radius> <height>) | (rect) | (set_point n) | (rm)",
  func = command_handler,
})
