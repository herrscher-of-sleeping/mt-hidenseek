local mod_table = {}

local util = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/util.lua")
local db = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/db.lua")
mod_table.db = db

local models = {}

local gamemodel = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/gamemodel.lua").init(mod_table)

function mod_table.get_nearest_model(pos)
  local nearest_distance = math.huge
  local nearest_model_name
  for model_name, model in pairs(models) do
    -- minetest.chat_send_all("model_name: " .. tostring(model_name))
    local model_pos = model:get_pos()
    local dx = pos.x - model_pos.x
    local dy = pos.y - model_pos.y
    local dz = pos.z - model_pos.z
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    if distance < nearest_distance then
      nearest_distance = distance
      nearest_model_name = model_name
    end
  end
  return nearest_model_name, models[nearest_model_name]
end

local timers = {}

function mod_table.timer(length, callback)
  local timer = { remaining_time = length, callback = callback }
  timers[timer] = true
  return timer
end

local function update_timer(timer, dt)
  if timer.remaining_time <= 0 then
    timer.callback()
    timers[timer] = nil
  else
    timer.remaining_time = timer.remaining_time - dt
  end
end

local function update_timers(dt)
  for timer in pairs(timers) do
    update_timer(timer, dt)
  end
end

local multitimers = {}

function mod_table.multitimer(interval, runs, callback)
  local timer = {
    remaining_time = interval,
    remaining_runs = runs,
    callback = callback,
    interval = interval,
    runs = runs,
  }
  multitimers[timer] = true

  return timer
end

local function update_multitimer(timer, dt)
  if timer.remaining_time <= 0 then
    timer.remaining_time = timer.remaining_time + timer.interval
    timer.remaining_runs = timer.remaining_runs - 1

    timer.callback(timer.runs - timer.remaining_runs)
    if timer.remaining_runs == 0 then
      multitimers[timer] = nil
    end
  else
    timer.remaining_time = timer.remaining_time - dt
  end
end

local function update_multitimers(dt)
  for timer in pairs(multitimers) do
    update_multitimer(timer, dt)
  end
end

-- register nodes
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/node_startnode.lua").init(mod_table)
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/node_border.lua").init(mod_table)
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/tool_invis.lua").init(mod_table)
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/tool_capture.lua").init(mod_table)

local storage = db.storage

minetest.register_chatcommand("dump_maps", {
  func = function(name, param)
    return true, "Maps: " .. storage:get_string("maps")
  end,
})

minetest.register_chatcommand("dump_models", {
  func = function(name, param)
    local model_names = {}
    for model_name, model in pairs(models) do
      local state = model:get_state()
      table.insert(model_names, model_name .. "(" .. state .. ")")
    end
    return true, "Models: " .. table.concat(model_names, ", ")
  end,
})

minetest.register_chatcommand("tpto", {
  func = function(name, param)
    if not (name == "test2" or name == "singleplayer") then
      return false, "You are not allowed to tp"
    end
    local block = db.get_map_position(param)
    if not block then
      return false, "No such map: " .. param
    end
    local pos = {
      x = block.x,
      y = block.y + 1,
      z = block.z,
    }
    minetest.get_player_by_name(name):set_pos(pos)
    return true
  end
})

minetest.register_chatcommand("start_game", {
  privs = { },
  func = function(name, param)
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

      models[map_name], err = gamemodel.new(map_name, pos)
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
  end,
})

local function initialize_models()
  local all_maps = db.get_all_maps()
  for map_name, map_pos in pairs(all_maps) do
    local err
    models[map_name], err = gamemodel.new(map_name, map_pos)
    if not models[map_name] then
      return false, err
    end
  end
end

initialize_models()

minetest.register_globalstep(function(dt)
  update_timers(dt)
  update_multitimers(dt)
  for map_name, model in pairs(models) do
    model:update(dt)
  end
end)