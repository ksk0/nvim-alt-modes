local M = {}
local extend_list = vim.fn.extend
local flatten = vim.fn.flatten

-- ============================================================================
-- list functions
--
local count_members = function(list)
  local count = {}
  for _,v in ipairs(list) do
    count[v] = count[v] and count[v] + 1 or 1
  end

  return count
end

M.union = function(list_a, ...)
  local union = {}
  local result = {}

  for _,v in ipairs(flatten(extend_list(list_a, {...}))) do
    if not union[v] then
      table.insert(result, v)
      union[v] = true
    end
  end

  return result
end

M.intersection = function(list_a, ...)
  local count = count_members(extend_list(list_a, M.union(...)))
  local result = {}

  for _,v in ipairs(list_a) do
    if count[v] > 1 then
      table.insert(result, v)
    end
  end

  return result
end

M.sub = function(list_a, ...)
  local section = M.intersection(list_a, M.union(...))
  local count = count_members(extend_list(list_a, section))
  local result = {}

  for _,v in ipairs(list_a) do
    if count[v] == 1 then

      table.insert(result, v)
    end
  end

  return result
end

return M
