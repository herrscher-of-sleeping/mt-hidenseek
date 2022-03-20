local HideNSeek

local function command_handler(name, param)
  local util = HideNSeek.util
  local db = HideNSeek.db
  local models = HideNSeek:get_models()
  local params = util.split_string(param)

  if #params < 3 then
    return nil, "Format: /start_game map_name seeker hider1 [hider2...]"
  end
  local map_name = params[1]
  local err
  if not models[map_name] then
    local pos = db.get_map_position(map_name)

    if not pos then
      return false, "No such map found: '" .. map_name .. "'"
    end

    models[map_name], err = HideNSeek.Gamemodel(map_name, pos)
  end

  if not models[map_name] then
    return false, err
  end

  local seeker = params[2]
  local hiders = {}
  for i = 3, #params do
    table.insert(hiders, params[i])
  end

  return models[map_name]:start_game(seeker, hiders)
end


local function init(mod_namespace)
  HideNSeek = mod_namespace
  minetest.register_chatcommand("hs_start", {
    privs = { hs_admin = true },
    func = command_handler
  })
end

return {
  init = init
}
