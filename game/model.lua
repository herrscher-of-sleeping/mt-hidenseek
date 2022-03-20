local HideNSeek

local unpack = _G.unpack or table.unpack
local model_metatable = {}
model_metatable.__index = model_metatable

model_metatable.states = {
  INACTIVE = 1,
  WARMUP = 2,
  ACTIVE = 3,
  FADE = 4,
}

local settings_fields = {
  "warmup_time",
  "game_time",
  "finish_time",
  "invis_time",
  "invis_cooldown",
  "search_tool_cooldown",
}

function model_metatable:timer(length, on_finish)
  if not length then
    error("Length should positive number")
  end
  local timer = { remaining_time = length, callback = on_finish }
  self._timers[timer] = true
  return timer
end

function model_metatable:multitimer(interval, runs, on_finish)
  local timer = {
    remaining_time = interval,
    remaining_runs = runs,
    callback = on_finish,
    interval = interval,
    runs = runs,
  }
  self._multitimers[timer] = true

  return timer
end

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

function model_metatable:start()
  self._state = self.states.WARMUP
  self._settings = read_settings()

  self:_add_player_items()

  self:multitimer(1, self._settings.warmup_time, function(count)
    minetest.chat_send_all("Starting game... count " .. count)
    if count == self._settings.warmup_time then
      self._state = self.states.ACTIVE
      self:timer(self._settings.game_time, function()
        self:_game_finish_callback()
      end)
    end
  end)
end

function model_metatable:get_settings()
  return self._settings
end

function model_metatable:start_game(seeker, hiders)
  local pos = { x = self._pos.x, y = self._pos.y, z = self._pos.z }

  pos.y = pos.y + 1

  local seeker_player_object = minetest.get_player_by_name(seeker)
  if not seeker_player_object then
    return false, "Seeker is not online: " .. seeker
  end

  local hider_player_objects = {}
  for i = 1, #hiders do
    hider_player_objects[i] = minetest.get_player_by_name(hiders[i])
    if not hider_player_objects[i] then
      return false, "Hider is not online: " .. hiders[i]
    end
  end

  seeker_player_object:set_pos(pos)

  for i = 1, #hider_player_objects do
    pos.x = pos.x + 1
    hider_player_objects[i]:set_pos(pos)
  end

  self._seekers = { seeker }
  self._seekers_set = { seeker = true }
  self._hiders = { unpack(hiders) } -- copy table
  self._hiders_set = {}
  for _, name in pairs(self._hiders) do
    self._hiders_set[name] = true
  end

  self:start()

  return true, "Teleported players to map '" .. self._map_name .. "'"
end

function model_metatable:get_pos()
  return { x = self._pos.x, y = self._pos.y, z = self._pos.z }
end

function model_metatable:get_hiders()
  local hiders = {}
  for _, player_name in pairs(self._hiders) do
    local player = minetest.get_player_by_name(player_name)
    if player then
      table.insert(hiders, {
        name = player_name,
        pos = player:get_pos()
      })
    end
  end
  return hiders
end

function model_metatable:capture_hider(seeker_name, player_name)
  local seeker_found
  for i = 1, #self._seekers do
    if self._seekers[i] == seeker_name then
      seeker_found = true
      break
    end
  end
  if not seeker_found then
    return false, "Player " .. seeker_name .. " tried to capture hider, but they're not a seeker"
  end
  if self._state ~= model_metatable.states.ACTIVE then
    return false, "Game is not active"
  end
  for i, name in ipairs(self._hiders) do
    if name == player_name then
      table.remove(self._hiders, i)
      table.insert(self._captured_hiders, name)
      return true
    end
  end
  return false, "Couldn't find hider " .. player_name
end

function model_metatable:_game_finish_callback()
  self._state = self.states.INACTIVE
  minetest.chat_send_all("ggwp")
end

function model_metatable:_update_timers(dt)
  for timer in pairs(self._timers) do
    if timer.remaining_time <= 0 then
      timer.callback()
      self._timers[timer] = nil
    else
      timer.remaining_time = timer.remaining_time - dt
    end
  end

  for timer in pairs(self._multitimers) do
    if timer.remaining_time <= 0 then
      timer.remaining_time = timer.remaining_time + timer.interval
      timer.remaining_runs = timer.remaining_runs - 1
      timer.callback(timer.runs - timer.remaining_runs)
      if timer.remaining_runs == 0 then
        self._multitimers[timer] = nil
      end
    else
      timer.remaining_time = timer.remaining_time - dt
    end
  end
end

function model_metatable:update(dt)
  self:_update_timers(dt)
  if self._state == self.states.ACTIVE then
    if #self._hiders == 0 then
      minetest.chat_send_all("All rebels found")
      self._state = self.states.FADE
      self._timers = {}
      self._multitimers = {}
      self:_remove_player_items()
      self:timer(self._settings.finish_time, function()
        self:_game_finish_callback()
      end)
    end
  end
end

function model_metatable:get_all_players()
  local all_players_in_model = {}
  for _, name in pairs(self._seekers) do
    table.insert(all_players_in_model, name)
  end
  for _, name in pairs(self._hiders) do
    table.insert(all_players_in_model, name)
  end
  return all_players_in_model
end

function model_metatable:get_hiders()
  return self._hiders
end

function model_metatable:get_seekers()
  return self._seekers
end

function model_metatable:_add_player_items()
  local hiders = self:get_hiders()
  for _, name in pairs(hiders) do
    local player = minetest.get_player_by_name(name)
    if player then
      player:get_inventory():set_list("main", {
        "hidenseek:invis_tool",
      })
    end
  end

  local seekers = self:get_seekers()
  for _, name in pairs(seekers) do
    local player = minetest.get_player_by_name(name)
    if player then
      player:get_inventory():set_list("main", {
        "hidenseek:capture_tool",
        "hidenseek:search_tool",
      })
    end
  end
end

function model_metatable:_remove_player_items()
  local all_players_in_model = self:get_all_players()
  for _, name in pairs(all_players_in_model) do
    local player = minetest.get_player_by_name(name)
    if player then
      player:get_inventory():set_list("main", {})
    end
  end
end

function model_metatable:get_state()
  return self._state
end

function model_metatable:destroy()
end

local function make_model(map_name, pos)
  local model = {
    _map_name = map_name,
    _pos = pos,
    _seekers = {},
    _hiders = {},
    _captured_hiders = {},
    _state = model_metatable.states.INACTIVE,
    _timers = {},
    _multitimers = {},
  }

  setmetatable(model, model_metatable)

  return model
end

return {
  init = function(mod_namespace)
    HideNSeek = mod_namespace
    HideNSeek.Gamemodel = make_model
  end
}
