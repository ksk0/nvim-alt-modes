local fader = require("fade-color")
local am    = require("alt-modes")

local api = vim.api
local fn  = vim.fn
local map = vim.tbl_map
local filter = vim.tbl_filter
local extend = vim.fn.extend

local F = nil
local SHADES = 7

local help_mode = {
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

am:add("alt-mode-help", help_mode)

local set_higlighting = function()
  local source = 'Question'
  -- local destination = 'Question'

  -- local hi_src = api.nvim_get_hl_by_name(source, true)
  -- local hi_dst = api.nvim_get_hl_by_name(destination, true)
  -- local hi_float   = api.nvim_get_hl_by_name("FloatBorder", true)

  local hi_normal  = api.nvim_get_hl_by_name("Normal", true)
  local hi_special = api.nvim_get_hl_by_name("NonText", true)
  local hi_keymap  = api.nvim_get_hl_by_name("Directory", true)
  local hi_desc    = api.nvim_get_hl_by_name(source, true)

  local special_fg = hi_special.foreground or hi_normal.foreground
  local keymap_fg  = hi_keymap.foreground or hi_normal.foreground
  local desc_fg    = hi_desc.foreground or hi_normal.foreground
  local desc_bg    =  hi_normal.background

  vim.cmd("highlight AltModeHelpSpecial guifg=#" .. string.format("%06x", special_fg))
  vim.cmd("highlight AltModeHelpTitle   guifg=#" .. string.format("%06x", keymap_fg) .. " gui=bold")
  vim.cmd("highlight AltModeHelpLhs     guifg=#" .. string.format("%06x", keymap_fg))
  vim.cmd("highlight AltModeHelpDesc    guifg=#" .. string.format("%06x", desc_fg))

  local shades = math.floor(SHADES * 1.2 + 0.5)
  for i = 0,shades do
    local fade = i * (1 / shades)
    local fade_fg = fader.fade(desc_fg, desc_bg, fade)
    local hi_name = string.format("AltModeHelpFade%02d", i)

    vim.cmd("highlight " .. hi_name .. " guifg=#" .. string.format("%06x", fade_fg))
  end
end


-- ============================================================================
-- Helper functions
--
local max = function(list)
  if not list then
    return
  end

  local sorted = vim.deepcopy(list)
  table.sort(sorted, function(a, b) return b < a end)
  return sorted[1]
end

local valid_keymap = function(keymap)
  local desc = keymap.options.desc

  if desc == nil then
    return false
  elseif desc == "<help>" then
    return false
  elseif keymap.lhs:find("<Plug>") then
    return false
  else
    return true
  end
end

local order_by_description = function(key_a, key_b)
  local a = key_a.options.desc
  local b = key_b.options.desc

  do return a < b end
end

local order_by_lhs = function(key_a, key_b)
  local a = key_a.lhs
  local b = key_b.lhs

  local a_spec = a:find('<[^>]+>')
  local b_spec = b:find('<[^>]+>')

  if a_spec and b_spec then
    return a < b
  elseif a_spec then
    return false
  elseif b_spec then
    return true
  else
    return a < b
  end
end


-- ============================================================================
-- create buffer and window
--
local create_help_buffer = function()

  local options ={
    swapfile = false,
    buftype = 'nowrite',
    filetype = 'help',
    fileencoding = 'utf-8',
  }

  local buffer = api.nvim_create_buf(false, true)

  for opt, val in pairs(options) do
    vim.api.nvim_buf_set_option (buffer, opt, val)
  end

  return buffer
end

local create_help_window = function (buffer, height, width)
  local w_height = height or 40
  local w_width  = width  or 40

  local config = {
    relative = 'win',
    row    = 3,
    col    = 3,
    width  = w_width,
    height = w_height,
    border = 'rounded',
  }

  local options ={
    number = false,
    foldenable = false,
    colorcolumn = "",
    signcolumn = "no",
    scrolloff = 0,
    sidescrolloff = 0,
    winhl = 'Normal:FloatBorder',
  }

  local window = api.nvim_open_win(buffer, true, config)

  for opt, val in pairs(options) do
    vim.api.nvim_win_set_option (window, opt, val)
  end

  -- local lines = {}

  -- for _=1,w_height do
  --   table.insert(lines,"")
  -- end

  -- api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

  return window
end



-- ============================================================================
-- create helpt text (line by line with higlighting)
-- 
local center_text = function(text, width)
  local padding = (width - text:len()) / 2

  return (string.rep(" ", padding) .. text)
end

local construct_help_line  = function(format, keymap)
  local desc_full = keymap.options.desc
  local desc_trim = string.sub(desc_full,1,format.desc_len)
  local lhs  = keymap.lhs

  local highlight = {}
  local line = string.format(format.line, "", keymap.lhs, desc_trim)

  local special_start,special_end = lhs:find('<[^>]+>')

  if special_start ~= nil then
    table.insert(highlight, {
      h_name = "AltModeHelpSpecial",
      h_start = 0,
      h_end = special_end + 1,
    })

    table.insert(highlight, {
      h_name = "AltModeHelpLhs",
      h_start = special_end + 1,
      h_end = format.lhs_len + 3
    })

  else
    table.insert(highlight, {
      h_name = "AltModeHelpLhs",
      h_start = 0,
      h_end = format.lhs_len + 3
    })
  end

  if (format.desc_len < string.len(desc_full)) then

    table.insert(highlight, {
      h_name = "AltModeHelpDesc",
      h_start = format.lhs_len + 3,
      h_end   = - (SHADES + format.right_offset + 1)
    })

    for i=1,SHADES do
      table.insert(highlight, {
        h_name  = string.format("AltModeHelpFade%02d", i),
        h_start = format.win_width - (SHADES + format.right_offset) + (i - 1),
        h_end   = format.win_width - (SHADES + format.right_offset) + i,
      })
    end

  else
    table.insert(highlight, {
      h_name = "AltModeHelpDesc",
      h_start = format.lhs_len + 3,
      h_end = -1
    })
  end

  return {
    text = line,
    highlight = highlight
  }
end

local construct_help_title = function(format, state)
    local highlight_text = {{
      h_name = "AltModeHelpTitle",
      h_start = 0,
      h_end = -1
    }}

    local highlight_line = {{
      h_name = "FloatBorder",
      h_start = 0,
      h_end = -1
    }}

  return {
    {
      text = center_text(state.altmode.name, format.win_width),
      highlight = highlight_text,
    },
    {
      text = string.rep("─", format.win_width),
      highlight = highlight_line,
    }
  }
end

local construct_help_text = function(state)
  local keymaps  = filter(valid_keymap, state.altmode.keymaps)
  local lhs_list = map(function(kmap) return kmap.lhs end, keymaps)

  table.sort(keymaps, order_by_lhs)

  local format = {}

  format.left_offset  = 1
  format.right_offset = 1
  format.win_width    = fn.winwidth(F.window)
  format.win_height   = fn.winheight(F.window)

  format.lhs_len  = max(map(string.len, lhs_list)) or 0
  format.desc_len = format.win_width - format.lhs_len - format.left_offset - format.right_offset - 3
  format.line     = string.format("%%%ds%%%ds : %%s", format.left_offset, format.lhs_len)

  local text = {}

  text = extend(text, construct_help_title(format,state))

  for _,keymap in ipairs(keymaps) do
    table.insert(text, construct_help_line(format,keymap))
  end

  local rest = format.win_height - #keymaps - 1

  if rest == 0 then
    return text
  end

  local highlight = {{
    h_name  = "AltModeHelpDesc",
    h_start = 0,
    h_end   = -1,
  }}

  for _=1,rest do
    table.insert(text, { text = "", highlight = highlight})
  end

  return text
end


-- ============================================================================
-- main functions
--
local show_help = function (self, buffer)
  buffer = buffer or api.nvim_get_current_buf()

  local states = self._states[buffer]

  if not states then
    vim.notify("There is no state to show help for!")
    return
  end

  local state  = states[#states]

  F = {}
  F.buffer = create_help_buffer()
  F.window = create_help_window(F.buffer)

  local help_text = construct_help_text(state)

  api.nvim_buf_set_lines(F.buffer, 0, -1, false, map(function(a) return a.text end, help_text))

  for i, line in ipairs(help_text) do
    for _, hi in ipairs(line.highlight) do
      api.nvim_buf_add_highlight(F.buffer, -1, hi.h_name, (i - 1), hi.h_start, hi.h_end)
    end
  end

  am:enter("alt-mode-help", F.buffer)

  api.nvim_win_set_cursor(F.window, {1,0})

  -- local keymap_opts = {noremap = true}
  -- vim.api.nvim_buf_set_keymap(F.buffer, 'n', 'q', ':lua require("alt-modes"):help()<CR>', keymap_opts)
end

local hide_help = function ()
  -- vim.notify("Closing HELP window")
  api.nvim_win_close(F.window, true)
  -- vim.notify("Closed window !")
  api.nvim_buf_delete(F.buffer, {})
  -- vim.notify("I have closed everything!")

  am:exit(F.buffer)

  F = nil
end

local help = function(self, buffer)
  if F == nil then
    show_help(self, buffer)
  else
    hide_help()
  end
end

set_higlighting()

return help
