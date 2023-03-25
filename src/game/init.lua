--[[
Model is an object containing information about game match
and logic to work with that information.
It has, for instance, its own state, timers that only work in specific state,
it remembers players, and it dissolves when match ends,
effectively releasing players from having their duty to complete the match
and deleting all the timers.
--]]


local settings_lib = require "src/lib/settings"
local unpack = unpack or table.unpack

---@alias HideNSeek.Direction "n"|"s"|"w"|"e"

---@class HideNSeek.Model
---@field private _map_name string
---@field private _pos mt.Vector
---@field private _dir HideNSeek.Direction
---@field private _seekers {} TODO
---@field private _hiders {} TODO
---@field private _seekers_set { [table]: boolean }
---@field private _hiders_set { [table]: boolean }
---@field private _captured_hiders {} TODO
---@field private _state HideNSeek.Model.states
---@field private _timers {} TODO
---@field private _repeating_timers {} TODO
---@field private _settings { [string]: any }
local model_metatable = {}

model_metatable.__index = model_metatable ---@private

---@enum HideNSeek.Model.states
model_metatable.states = {
  INACTIVE = 1,
  WARMUP = 2,
  ACTIVE = 3,
  FADE = 4,
}

---@class HideNSeek.Timer
---@field remaining_time number
---@field callback fun(run_number: integer)

---@param length number
---@param on_finish fun()
---@return HideNSeek.Timer
function model_metatable:timer(length, on_finish)
  if not length then
    error("Length should positive number")
  end
  local timer = { remaining_time = length, callback = on_finish }
  self._timers[timer] = true
  return timer
end

---@class HideNSeek.repeating_timer
---@field remaining_time number
---@field remaining_runs integer
---@field callback fun(run_number: integer)
---@field interval number
---@field runs integer

---@param interval number
---@param runs integer
---@param on_finish fun(run_number: integer)
---@return HideNSeek.repeating_timer
function model_metatable:repeating_timer(interval, runs, on_finish)
  local timer = {
    remaining_time = interval,
    remaining_runs = runs,
    callback = on_finish,
    interval = interval,
    runs = runs,
  }
  self._repeating_timers[timer] = true

  return timer
end

function model_metatable:start()
  self._state = self.states.WARMUP
  self._settings = settings_lib.get_settings()

  self:_add_player_items()

  self:repeating_timer(1, self._settings.warmup_time, function(count)
    minetest.chat_send_all("Starting game... count " .. count)
    if count == self._settings.warmup_time then
      self._state = self.states.ACTIVE
      self:timer(self._settings.game_time, function()
        self:_return_player_items()
        self:_game_finish_callback()
      end)
    end
  end)
end

---@return { [string]: any }
function model_metatable:get_settings()
  return self._settings
end

---@param facing_side HideNSeek.Direction
---@return mt.Vector
local function get_direction_vector(facing_side)
  if facing_side == "n" then
    return vector.new(0, 0, 1)
  elseif facing_side == "s" then
    return vector.new(0, 0, -1)
  elseif facing_side == "w" then
    return vector.new(-1, 0, 0)
  elseif facing_side == "e" then
    return vector.new(1, 0, 0)
  end
  return vector.new(0, 0, 1)
end

---@param seeker string
---@param hiders string[]
function model_metatable:start_game(seeker, hiders)
  local pos = vector.add(self._pos, vector.new(0, 1, 0))
  local dir = get_direction_vector(self._dir)
  local spawn_line_dir = vector.cross(dir, vector.new(0, 1, 0))

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

  local num_hiders = #hider_player_objects
  for i = 1, num_hiders do
    local offset = vector.multiply(spawn_line_dir, (i - 0.5 * num_hiders) / num_hiders)
    local new_pos = vector.add(
      vector.add(pos, vector.multiply(dir, 3)),
      offset
    )
    hider_player_objects[i]:set_pos(new_pos)
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

---@return mt.Vector
function model_metatable:get_pos()
  return { x = self._pos.x, y = self._pos.y, z = self._pos.z }
end

---@return {name: string, pos: mt.Vector}[]
function model_metatable:get_seekers()
  local seekers = {}
  for _, player_name in pairs(self._seekers) do
    local player = minetest.get_player_by_name(player_name)
    if player then
      table.insert(seekers, {
        name = player_name,
        pos = player:get_pos()
      })
    end
  end
  return seekers
end

---@return {name: string, pos: mt.Vector}[]
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

---@param seeker_name string
---@param player_name string
---@return boolean ok
---@return string? err
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

---@private
---Activated on game finish
function model_metatable:_game_finish_callback()
  self._state = self.states.INACTIVE
  minetest.chat_send_all("ggwp")
end

---@private
function model_metatable:_update_timers(dt)
  for timer in pairs(self._timers) do
    if timer.remaining_time <= 0 then
      timer.callback()
      self._timers[timer] = nil
    else
      timer.remaining_time = timer.remaining_time - dt
    end
  end

  for timer in pairs(self._repeating_timers) do
    if timer.remaining_time <= 0 then
      timer.remaining_time = timer.remaining_time + timer.interval
      timer.remaining_runs = timer.remaining_runs - 1
      timer.callback(timer.runs - timer.remaining_runs)
      if timer.remaining_runs == 0 then
        self._repeating_timers[timer] = nil
      end
    else
      timer.remaining_time = timer.remaining_time - dt
    end
  end
end

---@param dt number
function model_metatable:update(dt)
  self:_update_timers(dt)
  if self._state == self.states.ACTIVE then
    if #self._hiders == 0 then
      minetest.chat_send_all("gg wp")
      self._state = self.states.FADE
      self._timers = {}
      self._repeating_timers = {}
      self:_return_player_items()
      self:timer(self._settings.finish_time, function()
        self:_game_finish_callback()
      end)
    end
  end
end

---@return string[]
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

---@private
---Backups player's inventory and replaces inventory with "ability" items
function model_metatable:_add_player_items()
  local hiders = self:get_hiders()
  for _, hider in pairs(hiders) do
    local player = minetest.get_player_by_name(hider.name)
    if player then
      ---@type mt.ItemStack
      HideNSeek.inventory_manager.backup_player_inventory(player)
      player:get_inventory():set_list("main", {
        "hidenseek:invis",
      })
    end
  end

  local seekers = self:get_seekers()
  for _, seeker in pairs(seekers) do
    local player = minetest.get_player_by_name(seeker.name)
    if player then
      HideNSeek.inventory_manager.backup_player_inventory(player)
      player:get_inventory():set_list("main", {
        "hidenseek:invis",
        "hidenseek:capture",
        "hidenseek:search",
      })
    end
  end
end

---@private
---Restores player's inventory after the game
function model_metatable:_return_player_items()
  local all_players_in_model = self:get_all_players()
  for _, name in pairs(all_players_in_model) do
    local player = minetest.get_player_by_name(name)
    if player then
      HideNSeek.inventory_manager.restore_player_inventory(player)
    end
  end
end

---@return HideNSeek.Model.states
function model_metatable:get_state()
  return self._state
end

---@return string # map name on which model is running
function model_metatable:get_name()
  return self._map_name
end

---TODO: What does it do?
function model_metatable:destroy()
end

---@param map_name string
---@param map_info table
---@return HideNSeek.Model
local function make_model(map_name, map_info)
  if not map_info.position then
    minetest.log("error", "map_info: " .. minetest.serialize(map_info))
  end
  local model = {
    _map_name = map_name,
    _pos = map_info.position,
    _dir = map_info.direction,
    _seekers = {},
    _hiders = {},
    _captured_hiders = {},
    _state = model_metatable.states.INACTIVE,
    _timers = {},
    _repeating_timers = {},
  }

  setmetatable(model, model_metatable)

  return model
end

HideNSeek.Gamemodel = make_model
require "src/game/inventory_manager"
