local native = require('alt-modes.native')

native._LHS_COMBOS = native._LHS_COMBOS or {}

LHS_COMBOS = native._LHS_COMBOS

local function C(lhs)
  if type(lhs) == 'table' then
    local combos = {}

    for _,kmap in ipairs(lhs) do
      table.insert(combos, C(kmap))
    end

    return combos
  end

  lhs = lhs:gsub('<[^>]+>', function(s) return s:lower() end)

  if LHS_COMBOS[lhs] then return LHS_COMBOS[lhs] end

  local combos = {}
  local combo  = ""
  local special


  lhs:gsub('.',
    function (c)
      if not special then
        if c == '<' then
          special = '<'
        else
          combo = combo .. c
          table.insert(combos, combo)
        end

      else
        special = special .. c

        if c == '>' then
          combo   = combo .. special
          special = nil

          table.insert(combos, combo)
        end
      end
    end
  )

  if special then
    combo   = combo .. special
    table.insert(combos, combo)
  end

  LHS_COMBOS[lhs] = combos

  return combos
end

return C
