-- I wanna have good old require
-- and don't want to deal with dofile
-- as it makes things unnecessarily more complicated.
-- So let's run mod in modified environment
-- with own hand-crafted "require".
local loaded = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())

local function shallow_copy(tab)
  local new_tab = {}
  for k, v in pairs(tab) do
    new_tab[k] = v
  end
  return new_tab
end

local module_env = shallow_copy(_ENV or getfenv())

local function file_exists(path)
  local fd = io.open(path, "r")
  if not fd then
    return false
  end
  fd:close()
  return true
end

local function loadfile(path, mode, module_env, chunk_name)
  assert(type(path) == "string")
  local fd = io.open(path, "r")
  assert(fd)
  local contents = fd:read("*a")
  fd:close()
  assert(module_env.HideNSeek)
  local loaded = loadstring(contents, chunk_name, mode, module_env)
  if setfenv then
    setfenv(loaded, module_env)
  end
  assert(loaded)
  return loaded
end

local package = {
  loaded = {},
}

local function require(path)
  assert(type(path) == "string")
  if package.loaded[path] then
    return package.loaded[path]
  end
  local folder_path = modpath .. "/" .. path .. "/init.lua"
  local file_path = modpath .. "/" .. path .. ".lua"
  local chunk_name = path
  local loaded
  if file_exists(folder_path) then
    chunk_name = chunk_name .. "/init.lua"
    loaded = loadfile(folder_path, "t", module_env, chunk_name)
  elseif file_exists(file_path) then
    chunk_name = chunk_name .. ".lua"
    loaded = loadfile(file_path, "t", module_env, chunk_name)
  else
    error("File doesn't exist: " .. path)
  end
  assert(loaded, "Couldn't load module " .. path)
  package.loaded[path] = loaded() or true
  return package.loaded[path]
end

module_env.require = require
module_env.package = package
module_env.HideNSeek = {} -- mod namespace

require("src")
