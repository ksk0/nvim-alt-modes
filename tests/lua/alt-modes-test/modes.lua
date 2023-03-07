local normal = require("alt-modes.native.normal")

local modes = {}

local exit_testing_mode = function()
  require('alt-modes'):exit()
  LUA_TESTING_ME = nil
end

modes.testing = {
  name = 'TESTING',
  mode = 'n',
  exit = '',
  help = 'h',

  timeout = 500,

  overlay = {
    keep = {
      global = {"zp"},

      native = {
        { ":", "j", "k"},
        normal.mode.ex,
        normal.movement,
        normal.scroll,
        normal.folding,
      }
    },
  },

  options = {
    -- noremap = true,
    -- nowait  = true,
    -- silent  = false,
    -- expr    = false,
  },

  keymaps = {
    {
      {
        lhs  = '<C-X>',
        rhs  = '',
        desc = '<C-X>AB',
      },
      {
        lhs  = 'AB<C-X>',
        rhs  = '',
        desc = 'AB<C-X>',
      },
      {
        lhs  = 'AB<C-X>CD',
        rhs  = '',
        desc = 'AB<C-X>CD',
      },
      {
        lhs  = 'AB<C-X>CD<C-Z>',
        rhs  = '',
        desc = 'AB<C-X>CD<C-Z>',
      },
      {
        lhs  = 'AB<C-X>CD<C-Z>EF',
        rhs  = '',
        desc = 'AB<C-X>CD<C-Z>EF',
      },
      {
        lhs  = 'AB<C-X><C-Z>',
        rhs  = '',
        desc = 'AB<C-X><C-Z>',
      },
      {
        lhs  = 'AB<C-X><C-Z>EF',
        rhs  = '',
        desc = 'AB<C-X><C-Z>EF',
      },
      {
        lhs  = 'ABCDEFGHIJKLMNOPQR',
        rhs  = '',
        desc = 'ABCDEFGHIJKLMNOPQR',
      },
    },
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
      {
        lhs  = '<esc>',
        rhs  = exit_testing_mode,
        desc = 'Exit testing mode',
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

modes.no_desc = {
  name = 'NO DESC',
  mode = 'n',
  exit = '<esc>',
  help = 'h',

  timeout = 500,

  overlay = {
    keep = {
      native = {
        ":",
        -- normal.movement,
        -- normal.scroll,
      }
    },
  },

  options = {
    -- noremap = true,
    nowait  = false,
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
