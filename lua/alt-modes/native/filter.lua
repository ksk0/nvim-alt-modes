local function filter(keymap_tree)
  for key,val in pairs(keymap_tree) do
    if type(val) == "table" then
      keymap_tree[key] = filter(val)
    else
      keymap_tree[key] = val:gsub("{[^}]+}", "")
    end
  end

  return keymap_tree
end

return filter

