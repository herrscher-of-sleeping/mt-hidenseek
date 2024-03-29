local M = {}

function M.split_string(str)
  local substrings = {}
  for word in str:gmatch("[^%s]+") do
    table.insert(substrings, word)
  end
  return substrings
end

return M
