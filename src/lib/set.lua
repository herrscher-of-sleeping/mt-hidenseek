local set_mt = {}

function set_mt:__index(k)
  return rawget(self._set, k)
end

function set_mt:__len()
  return rawget(self, "_size")
end

function set_mt:__newindex(k, v)
  local has_element = rawget(self._set, k)
  if not has_element and v then
    rawget(self, "_set")[k] = true
    local new_size = rawget(self, "_size") + 1
    rawset(self, "_size", new_size)
  elseif has_element and not v then
    rawget(self, "_set")[k] = nil
    local new_size = rawget(self, "_size") - 1
    assert(new_size >= 0)
    if not next(self._set) then
      assert(new_size == 0)
    end
    rawset(self, "_size", new_size)
  end
end

local function make_set()
  local set = {
    _size = 0,
    _set = {},
  }
  return setmetatable(set, set_mt)
end

local function run_insert_delete_test()
  local s = make_set()
  assert(#s == 0)
  assert(not s[1])
  s[1] = 5
  s[2] = true
  assert(s[1] and s[2])
  assert(#s == 2)
  s[2] = false
  s[1] = nil
  assert(not s[1])
  assert(#s == 0)
  print("run_insert_delete_test: ok")
end

local function run_tests()
  run_insert_delete_test()
end

-- run_tests()

return {
  run_tests = run_tests,
  make_set = make_set,
}
