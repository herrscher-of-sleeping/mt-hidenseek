local HideNSeekMod

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
}

local function read_settings()
  local default_settings_object = Settings(minetest.get_modpath("hidenseek") .. "/default_settings.conf")
  local settings_object = minetest.settings

  local settings_table = {}
  for _, field in pairs(settings_fields) do
    local field_path = "hidenseek." .. field
    settings_table[field] = settings_object:get(field_path) or default_settings_object:get(field_path)
    if not settings_table[field] then
      error(field_path .. " is not set in configuration")
    end
  end
  return settings_table
end

function model_metatable:start()
  self._state = self.states.WARMUP

  local function error() end
  self._settings = read_settings()

  HideNSeekMod.multitimer(1, self._settings.warmup_time, function(count)
    minetest.chat_send_all("Starting game... count " .. count)
    if count == self._settings.warmup_time then
      self._state = self.states.ACTIVE
      HideNSeekMod.timer(self._settings.game_time, function()
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

function model_metatable:update(dt)
  if self._state == self.states.ACTIVE then
    if #self._hiders == 0 then
      minetest.chat_send_all("All rebels found")
      self._state = self.states.FADE
      HideNSeekMod.timer(self._settings.finish_time, function()
        self:_game_finish_callback()
      end)
    end
  end
end

function model_metatable:get_state()
  return self._state
end

local function make_model(map_name, pos)
  local model = {
    _map_name = map_name,
    _pos = pos,
    _seekers = {},
    _hiders = {},
    _captured_hiders = {},
    _state = model_metatable.states.INACTIVE,
  }

  setmetatable(model, model_metatable)

  return model
end

return {
  init = function(HideNSeekMod_)
    HideNSeekMod = HideNSeekMod_
    return {
      new = make_model
    }
  end
}