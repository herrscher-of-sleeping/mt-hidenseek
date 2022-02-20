local function make_column(x, y, z, h, node)
  for i = 0, h - 1 do
    local pos = { x = x, y = y + i, z = z }
    local existing_node = minetest.get_node(pos)
    if existing_node.name == "air" or existing_node.name == "hidenseek:border" then
      minetest.set_node(pos, { name = node } )
    end
  end
end

local function toggle_wall(pos, radius, height, node)
  local x = radius
  local z = 0

  make_column(pos.x + radius, pos.y, pos.z, height, node)
  make_column(pos.x - radius, pos.y, pos.z, height, node)
  make_column(pos.x, pos.y, pos.z + radius, height, node)
  make_column(pos.x, pos.y, pos.z - radius, height, node)

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

    make_column(x + pos.x, pos.y, z + pos.z, height, node)
    make_column(-x + pos.x, pos.y, z + pos.z, height, node)
    make_column(x + pos.x, pos.y, -z + pos.z, height, node)
    make_column(-x + pos.x, pos.y, -z + pos.z, height, node)

    if x ~= z then
      make_column(z + pos.x, pos.y, x + pos.z, height, node)
      make_column(-z + pos.x, pos.y, x + pos.z, height, node)
      make_column(z + pos.x, pos.y, -x + pos.z, height, node)
      make_column(-z + pos.x, pos.y, -x + pos.z, height, node)
    end
  end
end

local function init(mod_table)
  local db = mod_table.db
  local need_wall = true
  minetest.register_node("hidenseek:startnode", {
    description = "The initial node",
    tiles = {"wool_white.png"},
    is_ground_content = true,
    groups = {  oddly_breakable_by_hand = 3 },
    on_punch = function(pos)
      local round_pos = {
        x = math.floor(pos.x),
        y = math.floor(pos.y),
        z = math.floor(pos.z),
      }
      if need_wall then
        toggle_wall(round_pos, 30, 20, "hidenseek:border")
      else
        toggle_wall(round_pos, 30, 20, "air")
      end
      need_wall = not need_wall
    end,
    on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("formspec", "field[text;;${text}]")
    end,
    on_destruct = function(pos)
      local meta = minetest.get_meta(pos)
      local map_name = meta:get_string("text")
      db.remove_start_node(map_name)
    end,
    on_receive_fields = function(pos, formname, fields, sender)
      local player_name = sender:get_player_name()
      if minetest.is_protected(pos, player_name) then
        minetest.record_protection_violation(pos, player_name)
        return
      end
      local text = fields.text
      if not text then
        return
      end
      if string.len(text) > 20 then
        minetest.chat_send_player(player_name, "Map name is too long")
        return
      end
      minetest.log("action", player_name .. " set map name \"" .. text ..
        "\" to the map block at " .. minetest.pos_to_string(pos))
      local meta = minetest.get_meta(pos)
      local old_map_name = meta:get_string("text")
      meta:set_string("text", text)
      db.remove_start_node(old_map_name)
      db.add_start_node(text, pos)

      if #text > 0 then
        meta:set_string("infotext", text)
      else
        meta:set_string("infotext", '')
      end
    end,
  })
end

return {
  init = init,
}