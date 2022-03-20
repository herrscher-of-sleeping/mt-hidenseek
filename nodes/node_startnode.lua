local HideNSeek

local node_description = {
  description = "The initial node",
  tiles = {"wool_white.png"},
  is_ground_content = true,
  groups = {  oddly_breakable_by_hand = 3 },
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", "field[text;;${text}]")
  end,
  on_destruct = function(pos)
    local meta = minetest.get_meta(pos)
    local map_name = meta:get_string("text")
    HideNSeek.db.remove_start_node(map_name)
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
    HideNSeek.db.remove_start_node(old_map_name)
    HideNSeek.db.add_start_node(text, pos)

    if #text > 0 then
      meta:set_string("infotext", text)
    else
      meta:set_string("infotext", '')
    end
  end,
}

local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_node("hidenseek:startnode", node_description)
end

return {
  init = init,
}
