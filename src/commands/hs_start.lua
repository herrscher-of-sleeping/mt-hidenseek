local function command_handler(name, params)
  local util = HideNSeek.util
  local db = HideNSeek.db
  local models = HideNSeek:get_models()

  if #params < 3 then
    return nil, "Format: /hs start map_name seeker hider1 [hider2...]"
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

HideNSeek.register_chatcommand("start", {
  privs = { hs_admin = true },
  description = "Start game",
  params = "map_name seeker hider1 [hider2...]",
  func = command_handler,
})
