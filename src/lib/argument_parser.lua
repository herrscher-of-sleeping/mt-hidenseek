local function break_line(line)
  local args = {}
  local arg_acc = {}
  local open_quote_type
  local previous_character

  local function push_argument()
    if next(arg_acc) then
      table.insert(args, table.concat(arg_acc))
      arg_acc = {}
    end
  end

  local function push_char(c)
    table.insert(arg_acc, c)
  end

  for i = 1, #line do
    local character = line:sub(i, i)
    if character == '"' or character == "'" then
      if open_quote_type == character then
        push_argument()
        open_quote_type = nil
      elseif not open_quote_type then
        if previous_character ~= " " then
          return nil
        end
        open_quote_type = character
      end
    elseif character == " " and not open_quote_type then
      push_argument()
    else
      push_char(character)
    end
    previous_character = character
  end
  if not open_quote_type then
    push_argument()
  else
    return nil
  end
  if not args[1] then
    return nil
  end
  return args
end

local cases = {
  { [[hs start]], { "hs", "start" }},
  { [[hs 'start']], { "hs", "start" }},
  { [[hs "start"]], { "hs", "start" }},
  { [[hs 'start"]], nil },
  { [[hs"start"]], nil },
  { [[hs start"]], nil },
  { [[hs "start]], nil },
  { [[hs a b]], { "hs", "a", "b" }},
  { [[ hs   a   b    ]], { "hs", "a", "b" }},
  { [[ hs add player "Name With Spaces" ]], { "hs", "add", "player", "Name With Spaces" }},
  { [[ hs add player "Name With Spaces ruined version]], nil},
}

local function pretty_format(var)
  if type(var) == "table" then
    return "[" .. table.concat(var, ",") .. "]"
  else
    return tostring(var)
  end
end

local function assert_equal(expected, result)
  if type(expected) ~= type(result) then
    return false, "Error: expected " .. type(expected)
      .. ", got " .. type(result) .. ": " .. pretty_format(result)
  elseif type(expected) == "table" then
    if #expected ~= #result then
      return false, "Error: expected " .. pretty_format(expected)
      .. ", got " .. pretty_format(result)
    else
      for i = 1, #expected do
        if expected[i] ~= result[i] then
          return false, "Error: expected " .. pretty_format(expected)
          .. ", got " .. pretty_format(result)
        end
      end
    end
  end
  return true
end

local function run_tests()
  for i = 1, #cases do
    local result = break_line(cases[i][1])
    local expected = cases[i][2]
    local ok, msg = assert_equal(expected, result)
    if not ok then
      print(("Test #%d (%s) fail: %s"):format(i, cases[i][1], msg))
    else
      print(("Test %d ok"):format(i))
    end
  end
end

-- run_tests()

return {
  break_line = break_line
}
