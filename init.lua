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
load_module "game/model"
load_module "game/settings"
load_module "game/register_skill"
load_module "game/inventory_manager"
-- register nodes
load_module "nodes/node_startnode"
load_module "nodes/node_border"
-- register skills
load_module "skills/invis"
load_module "skills/capture"
load_module "skills/search"
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
  return models[nearest_model_name]
end

function HideNSeek.get_model_by_player(player)
  if type(player) == "string" then
    player = minetest.get_player_by_name(player)
  end
  if not player then
    return
  end
  local pos = player:get_pos()
  local model = HideNSeek.get_nearest_model(pos)
  return model
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

local t = 0

minetest.register_globalstep(function(dt)
  t = t + dt
  if t > 1 then
    t = 0
  end
  for _, model in pairs(models) do
    model:update(dt)
  end
end)
