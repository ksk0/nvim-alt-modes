local normal = require("alt-modes.native.normal")

local modes = {}

modes.no_desc = {
  name = 'NO DESC',
  mode = 'n',
  exit = '<esc>',
  help = 'h',

  timeout = 200,

  overlay = {
    keep = {
      native = {
        ":",
        normal.movement,
        normal.scroll,
      }
    },
  },

  options = {
    -- noremap = true,
    -- nowait  = true,
    -- silent  = true,
    -- expr    = false,
  },

  keymaps = {
    {
      {
        lhs  = 'g?',
        rhs  = ':lua require("alt-modes"):help()<CR>',
      },
      {
        lhs  = 'h',
        rhs  = ':lua require("alt-modes"):help()<CR>',
      },
    },
    {
      {
        lhs  = 'o',
        rhs  = ':nmap <buffer><CR>',
        -- desc = 'Notify that "o" key has been pressed',
      },
      {
        lhs  = 'g',
        rhs  = 'lua vim.notify("Key \\"g\\" was pressed")',
      },
    },
    {
      lhs  = 'J',
      rhs  = 'lua vim.notify("Key \\"J\\" was pressed")',
    },
    {
      lhs  = 'L',
      rhs  = ':lua vim.notify("Key \\"L\\" was pressed")',
    },
    {
      {
        lhs  = 'P',
        rhs  = '<cmd>lua vim.notify("Key \\"P\\" was pressed")<CR>',
      },
    },

    {
      lhs  = 'O',
      rhs  = 'lua do print "AAAA" end',
      -- expr = true,
    },
  },
}

modes.testing = {
  name = 'TESTING',
  mode = 'n',
  exit = '<esc>',
  help = 'h',

  timeout = 200,

  overlay = {
    keep = {
      native = {
        ":",
        normal.movement,
        normal.scroll,
      }
    },
  },

  options = {
    -- noremap = true,
    -- nowait  = true,
    -- silent  = true,
    -- expr    = false,
  },

  keymaps = {
    {
      {
        lhs  = 'g?',
        rhs  = ':lua require("alt-modes"):help()<CR>',
        desc = 'Show help',
      },
      {
        lhs  = 'h',
        rhs  = ':lua require("alt-modes"):help()<CR>',
        desc = 'Show help',
      },
    },
    {
      {
        lhs  = 'o',
        rhs  = ':nmap <buffer><CR>',
        -- desc = 'Notify that "o" key has been pressed',
      },
      {
        lhs  = 'g',
        rhs  = 'lua vim.notify("Key \\"g\\" was pressed")',
        desc = 'Notify that "Z" key has been pressed',
      },
    },
    {
      lhs  = 'J',
      rhs  = 'lua vim.notify("Key \\"J\\" was pressed")',
      desc = 'Notify that "J" key has been pressed',
    },
    {
      lhs  = 'L',
      rhs  = ':lua vim.notify("Key \\"L\\" was pressed")',
      desc = 'Notify that "L" key has been pressed',
    },
    {
      {
        lhs  = 'P',
        rhs  = '<cmd>lua vim.notify("Key \\"P\\" was pressed")<CR>',
        desc = 'Notify that "P" key has been pressed',
      },
    },

    {
      lhs  = 'O',
      rhs  = 'lua do print "AAAA" end',
      desc = 'some expression test',
      -- expr = true,
    },
  },
}

modes.help_mode = {
  name = 'ALTMODE HELP',
  mode = 'n',
  exit = '',
  help = '',

  timeout = 200,
  overlay = {
    keep = {
      native = ":"
    }
  },

  keymaps = {
    {
      lhs  = 'q',
      rhs  = ':lua require("alt-modes"):help()<CR>',
    },
    {
      lhs  = 'g?',
      rhs  = ':lua vim.notify("Help TEST")<CR>',
    },
  },
}

-- print(vim.inspect(modes.testing.overlay))
-- print(vim.inspect(normal))

return modes
