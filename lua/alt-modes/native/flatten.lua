local fn = vim.fn

local function flatten(keymap_tree, level)
  local flatt_list = {}

  -- ==================================
  -- sort/uniq only once
  --
  if not level then
    if type(keymap_tree) ~= "table" then
      return {keymap_tree}
    else
        return fn.uniq(fn.sort(flatten(keymap_tree, 1)))
    end
  end

  for _,item in pairs(keymap_tree) do
    if type(item) == "table" then
      flatt_list = fn.extend(flatt_list, flatten(item, 1))
    else
      table.insert(flatt_list, item)
    end
  end

  return flatt_list
end

return flatten
