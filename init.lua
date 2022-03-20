local HideNSeek = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())

local loaded_modules = {}

function HideNSeek.load_module(modname)
  if loaded_modules[modname] then
    error("Module " .. modname .. " is already loaded")
  end
  loaded_modules[modname] = true
  local path = modpath .. "/" .. modname .. ".lua"
  return dofile(path).init(HideNSeek)
end

function HideNSeek.reload_module(modname)
  if not loaded_modules[modname] then
    return false, ""
  end
  local path = modpath .. "/" .. modname .. ".lua"
  dofile(path).init(HideNSeek, true)
  return true
end

local load_module = HideNSeek.load_module
-- register modules
load_module "db"
load_module "util"
load_module "gamemodel"

-- register nodes
load_module "nodes/node_startnode"
load_module "nodes/node_border"
-- register tools
load_module "tools/tool_invis"
load_module "tools/tool_capture"
load_module "tools/tool_search"
-- register priveleges
load_module "privileges/hs_admin"
-- register chat commands
load_module "commands/hs_border"
load_module "commands/hs_dump_maps"
load_module "commands/hs_maps"
load_module "commands/hs_start"
load_module "commands/hs_tp"
load_module "commands/hs_reload"
load_module "commands/hs_spawn"

local models = {}

function HideNSeek.get_models()
  return models
end

function HideNSeek.get_nearest_model(pos)
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

function HideNSeek.timer(length, callback)
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

function HideNSeek.multitimer(interval, runs, callback)
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

function HideNSeek.set_spawn_point(pos)
  HideNSeek._spawn_point = pos
  HideNSeek.db.storage:set_string("spawn_point", minetest.serialize(pos))
end

function HideNSeek.get_spawn_point()
  local spawn_point_str = HideNSeek.db.storage:get_string("spawn_point")
  local spawn_point = { 0, 0, 0 }
  if spawn_point_str and spawn_point_str ~= "" then
    spawn_point = minetest.deserialize(spawn_point_str)
  end
  HideNSeek._spawn_point = spawn_point
  return HideNSeek._spawn_point
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

local function initialize_models()
  local all_maps = HideNSeek.db.get_all_maps()
  for map_name, map_pos in pairs(all_maps) do
    local err
    models[map_name], err = HideNSeek.Gamemodel(map_name, map_pos)
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
