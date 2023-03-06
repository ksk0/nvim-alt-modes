local luacache = (_G.__luacache or {}).cache

local reload = function(what)
  what = what or 'alt-modes'

  local pattern = "^" .. vim.pesc(what) .. "."

  if luacache then
    luacache[what] = nil
  end

  if package.loaded[what] then
    package.loaded[what] = nil
  end

  for pack, _ in pairs(package.loaded) do
    if string.find(pack, pattern) then

      package.loaded[pack] = nil

      if luacache then
        luacache[pack] = nil
      end
    end
  end
end

return reload
