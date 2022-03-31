local settings_fields = {
  "warmup_time",
  "game_time",
  "finish_time",
  "invis_time",
  "invis_cooldown",
  "search_tool_cooldown",
}

local function read_settings()
  local default_settings_object = Settings(minetest.get_modpath("hidenseek") .. "/default_settings.conf")
  local settings_object = minetest.settings

  local settings_table = {}
  for _, field in pairs(settings_fields) do
    local field_path = "hidenseek." .. field
    settings_table[field] = settings_object:get(field_path) or default_settings_object:get(field_path)
    if tonumber(settings_table[field]) then
      settings_table[field] = tonumber(settings_table[field])
    end
    if not settings_table[field] then
      error(field_path .. " is not set in configuration")
    end
  end
  minetest.log("debug", minetest.serialize(settings_table))
  return settings_table
end


local function init(mod_namespace)
  mod_namespace.read_settings = read_settings
end

return {
  init = init,
}
