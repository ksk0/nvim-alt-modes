local M = {}

M.block = {
  normal = {
    ex = {'gQ'},
    cmdline = {':', '/', '?', '!'},
    replace = {'r', 'R', 'gR'},
    insert  = {'i', 'I', 'a', 'A', 'o', 'O', 'c', 'C', 's', 'S'},
    visual  = {'v', 'V', '<C-v>'},
    select  = {'gh', 'gH', 'g<C-h>'},
  },

  insert = {
    normal  = {'<esc>', '<C-c>', '<C-[>', '<C-o>', '<C-\\><C-n>', '<C-\\><C-g>'},
    replace = {'<insert>'},
  },

  replace = {
    normal = {'<esc>', '<C-o>'},
    insert = {'<insert>'},
  },

  visual = {
    normal  = {'<esc>', 'v', 'V', '<C-v>'},
    cmdline = {':'},
    select  = {'<C-g>', '<C-o>'},
    insert  = {'c', 'C'},
  },
}

-- lazy load natives
--
setmetatable(M, {
  __index = function(t, k)
    local module = "alt-modes.native." ..  k
    local ok, val = pcall(require, module)

    if ok then
      -- vim.notify("Found: " .. module)
      -- print("Found: " .. module)
      rawset(t, k, val)
    else
      val = nil
    end

    return val
  end,
})

return M
