local HideNSeek

local form = [[
field[name;name;${name}]
field[dir;direction;${dir}]
]]

local node_description = {
  description = "The initial node",
  tiles = { "hidenseek_startnode.png" },
  is_ground_content = true,
  groups = {  oddly_breakable_by_hand = 3 },
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", form)
  end,
  on_destruct = function(pos)
    local meta = minetest.get_meta(pos)
    local map_name = meta:get_string("name")
    HideNSeek.db.remove_start_node(map_name)
  end,
  on_receive_fields = function(pos, formname, fields, sender)
    local player_name = sender:get_player_name()
    if minetest.is_protected(pos, player_name) then
      minetest.record_protection_violation(pos, player_name)
      return
    end
    local name = fields.name
    if not name then
      return
    end
    local dir = fields.dir or "n"
    if string.len(name) > 20 then
      minetest.chat_send_player(player_name, "Map name is too long")
      return
    end
    minetest.log("action", player_name .. " set map name \"" .. name ..
      "\" to the map block at " .. minetest.pos_to_string(pos))
    local meta = minetest.get_meta(pos)
    local old_map_name = meta:get_string("name")
    meta:set_string("name", name)
    meta:set_string("dir", dir)
    HideNSeek.db.remove_start_node(old_map_name)
    HideNSeek.db.add_start_node(name, pos, dir)

    if #name > 0 then
      meta:set_string("infotext", name)
    else
      meta:set_string("infotext", '')
    end
    meta:set_string("formspec", form) -- update formspec in case of change in code
  end,
}

local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_node("hidenseek:startnode", node_description)
end

return {
  init = init,
}
