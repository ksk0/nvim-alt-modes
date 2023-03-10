local fader = require("fade-color")
local am    = require("alt-modes")

local api = vim.api
local fn  = vim.fn
local extend = vim.fn.extend

local SHADES = 7  -- number of shade level for dimming out text

local M = {}

local BUFFER
local WINDOW
local INITIALIZED


-- ============================================================================
-- init functions
--
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
      rhs  = ':lua require("alt-modes.core.help"):hide()<CR>',
    },
    {
      lhs  = 'g?',
      rhs  = ':lua vim.notify("Help TEST")<CR>',
    },
  },
}

local init_higlighting = function()

  local source = 'Question'

  local hi_normal  = api.nvim_get_hl_by_name("Normal", true)
  local hi_special = api.nvim_get_hl_by_name("NonText", true)
  local hi_keymap  = api.nvim_get_hl_by_name("Directory", true)
  local hi_desc    = api.nvim_get_hl_by_name(source, true)

  local special_fg = hi_special.foreground or hi_normal.foreground
  local keymap_fg  = hi_keymap.foreground or hi_normal.foreground
  local desc_fg    = hi_desc.foreground or hi_normal.foreground
  local desc_bg    = hi_normal.background

  vim.cmd("highlight AltModeHelpCursor  guifg=#" .. string.format("%06x", desc_bg) .. "guibg=#" .. string.format("%06x", desc_bg))
  vim.cmd("highlight AltModeHelpSpecial guifg=#" .. string.format("%06x", special_fg))
  vim.cmd("highlight AltModeHelpTitle   guifg=#" .. string.format("%06x", keymap_fg) .. " gui=bold")
  vim.cmd("highlight AltModeHelpLHS     guifg=#" .. string.format("%06x", keymap_fg))
  vim.cmd("highlight AltModeHelpDesc    guifg=#" .. string.format("%06x", desc_fg))

  local shades = math.floor(SHADES * 1.2 + 0.5)

  for i = 0,shades do
    local fade = i * (1 / shades)
    local fade_fg = fader.fade(desc_fg, desc_bg, fade)
    local hi_name = string.format("AltModeHelpFade%02d", i)

    vim.cmd("highlight " .. hi_name .. " guifg=#" .. string.format("%06x", fade_fg))
  end
end

local init_help_mode = function ()
  am:add("alt-mode-help", help_mode)
end

local initalize = function ()
  if INITIALIZED then return end

  init_higlighting()
  init_help_mode()

  INITIALIZED = true
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

  BUFFER = api.nvim_create_buf(false, true)

  for opt, val in pairs(options) do
    vim.api.nvim_buf_set_option (BUFFER, opt, val)
  end
end

local create_help_window = function (height, width)
  height = height or 40
  width  = width  or 40

  local config = {
    relative = 'win',
    row    = 3,
    col    = 3,
    width  = width,
    height = height,
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

  WINDOW = api.nvim_open_win(BUFFER, true, config)

  for opt, val in pairs(options) do
    vim.api.nvim_win_set_option (WINDOW, opt, val)
  end
end


-- ============================================================================
-- help formating functions
--
local center_text = function(text, width)
  local padding = (width - text:len()) / 2

  return (string.rep(" ", padding) .. text)
end

local format_lhs = function(lhs)
  return lhs:gsub('(<[^>]+>)',
    function(s)
      return s:gsub(' ','space')
    end
  )
end

local lhs_highlighting = function(lhs, format)
  lhs = format_lhs(lhs)

  local lhs_len   = format.lhs_len
  local offset    =  lhs_len - string.len(lhs)
  local highlight = {}

  while lhs ~= "" do
    local special_start,special_end = lhs:find('<[^>]+>')

    if special_start then
      -- if there are normal characters at
      -- the begginig add highlighting
      --
      if special_start ~= 1 then
        table.insert(highlight, {
          h_name  = "AltModeHelpLHS",
          h_start = offset + 1,
          h_end   = offset + special_start -- - 1
        })
      end

      table.insert(highlight, {
        h_name  = "AltModeHelpSpecial",
        h_start = offset + special_start,
        h_end   = offset + special_end + 1,
      })

      offset = offset + special_end
      lhs    = lhs:sub(special_end + 1)

      if lhs == "" then
        table.insert(highlight, {
          h_name  = "AltModeHelpLHS",
          h_start = offset + 1,
          h_end   = lhs_len + 3
        })

        break
      end

    else
      table.insert(highlight, {
        h_name  = "AltModeHelpLHS",
        h_start = offset  + 1,
        h_end   = lhs_len + 3
      })

      break
    end
  end

  return highlight
end

local desc_highlighting = function(text, format)
  local highlight = {}

  if (format.text_len < string.len(text)) then

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

  return highlight
end


-- ============================================================================
-- construstion functions
--
local construct_help_title = function(format, help_title)
  local highlight_text = {{
    h_name = "AltModeHelpCursor",
    h_start = 0,
    h_end = 0,
  },{
    h_name = "AltModeHelpTitle",
    h_start = 1,
    h_end = -1
  }}

  local highlight_line = {{
    h_name = "FloatBorder",
    h_start = 0,
    h_end = -1
  }}

  return {
    {
      text = center_text(help_title, format.win_width),
      highlight = highlight_text,
    },
    {
      text = string.rep("─", format.win_width),
      highlight = highlight_line,
    }
  }
end

local construct_help_text = function(format, raw_text)
  if (format.text_len < string.len(raw_text)) then
    -- return string.sub(raw_text,1,format.text_len)
    return raw_text:sub(1,format.text_len)
  else
    return raw_text
  end
end

local construct_help_line  = function(format, keymap)
  local highlight = vim.deepcopy(keymap.hi_lhs)

  return {
    text = construct_help_text(format, keymap.raw_text),
    highlight = extend(highlight, desc_highlighting(keymap.raw_text, format)),
  }
end

local construct_help_block = function (format, help_text)
  local block = {}

  for _,item in ipairs(help_text) do
    table.insert(block, construct_help_line(format, item))
  end

  -- add empty line at the end of the block
  --
  table.insert(block,
    {
      text = "",
      highlight = {{
        h_name  = "AltModeHelpDesc",
        h_start = 0,
        h_end   = -1,
      }}
    }
  )

  return block
end

local construct_help = function (self)
  local format = self._format

  -- =======================================
  -- if we already have help text and
  -- windows widht has not changed, we
  -- will keep it.
  --
  local win_width = fn.winwidth(WINDOW)

  if self.help and format.win_width == win_width then
    return
  end

  format.win_width  = win_width
  format.win_height = fn.winheight(WINDOW)
  format.text_len   = format.win_width - format.left_offset - format.right_offset + 1

  local help  = {}

  for _,block in ipairs(self._text) do
    help = extend(help, construct_help_block(format, block))
  end

  -- remove last empty line
  --
  table.remove(help)

  self.title = construct_help_title(format, self._title)
  self.help  = help
end


-- ============================================================================
-- help extraction functions
--
local function extract_lhs_width (help_text, max_len)
  max_len = max_len or 0

  local lhs_len

  for _,kmap in ipairs(help_text) do
    if vim.tbl_islist(kmap) then
      lhs_len = extract_lhs_width(kmap, max_len)
    else
      -- lhs_len = #kmap.lhs
      lhs_len = string.len(format_lhs(kmap.lhs))
    end

    if lhs_len > max_len then max_len = lhs_len end
  end

  return max_len
end

local function extract_help_blocks (keymaps, help_text)
  help_text = help_text or {}
  local help_block = {}

  table.insert(help_text, help_block)

  for _,kmap in ipairs(keymaps) do
    if vim.tbl_islist(kmap) then
      extract_help_blocks(kmap, help_text)
    else
      if kmap.options.desc then
        table.insert(help_block, {lhs = kmap.lhs, desc = kmap.options.desc})
      end
    end
  end

  return help_text
end

local extract_help_text = function (keymaps)
  local help_blocks = extract_help_blocks(keymaps)
  local help_text = {}

  for _,block in ipairs(help_blocks) do
    if #block ~= 0 then
      table.insert(help_text, block)
    end
  end

  return help_text
end

local extract_help = function (keymaps)
  local help_text = extract_help_text(keymaps)

  if #help_text == 0 then return end

  local lhs_width = extract_lhs_width(help_text)
  local format = {}

  format.lhs_len      = lhs_width
  format.left_offset  = 1
  format.right_offset = 1

  local line_format = string.format("%%%ds%%%ds : %%s", format.left_offset, format.lhs_len)

  -- ==========================================
  -- we can construct full help text, and lhs
  -- higlighting in advance, so we will do it
  --
  for _,block in ipairs(help_text) do
    for _,kmap in ipairs(block) do
      kmap.raw_text = string.format(line_format, "", format_lhs(kmap.lhs), kmap.desc)
      kmap.hi_lhs   = lhs_highlighting(kmap.lhs, format)
    end
  end

  return help_text, format
end


-- ============================================================================
-- show/hide help
--
local set_highlights = function (line, highlights)
  for _,hi in ipairs(highlights) do
    api.nvim_buf_add_highlight(BUFFER, -1, hi.h_name, line, hi.h_start, hi.h_end)
  end
end

local set_text = function(line, text)
  api.nvim_buf_set_lines(BUFFER, line, -1, false, {text})
end

local show_help_title = function (self)
  for i,line in ipairs(self.title) do
    local line_no = i - 1
    set_text(line_no, line.text)
    set_highlights(line_no, line.highlight)
  end
end

local show_help_text = function (self)
  local help = self.help
  local offset, visible = self:visible()

  for i = 1,visible do
    local line = help[(i+offset)]
    local line_no = i + 1

    set_text(line_no, line.text)
    set_highlights(line_no, line.highlight)
  end
end

local show_help_blanks = function (self)
  local _, visible = self:visible()
  local missing = self._format.win_height - visible - 2

  -- print("Height:  " .. self._format.win_height)
  -- print("Missing: " .. missing)
  -- print("Visible: " .. visible)

  if missing <= 0 then return end

  local highlights = {{
    h_name  = "AltModeHelpDesc",
    h_start = 0,
    h_end   = -1,
  }}

  for i = 1,missing do
    local line_no = i + visible + 1

    set_text(line_no, "")
    set_highlights(line_no, highlights)
  end
end


local show_help = function(self)
  self.offset = self.offset or 0

  initalize()

  show_help_title(self)
  show_help_text(self)
  show_help_blanks(self)

  api.nvim_win_set_cursor(WINDOW, {1,0})

  am:enter("alt-mode-help", BUFFER)
end

local hide_help = function()
  api.nvim_win_close(WINDOW, true)
  api.nvim_buf_delete(BUFFER, {})

  am:exit(BUFFER)

  BUFFER = nil
  WINDOW = nil
end

-- ============================================================================
-- default call
--
local setup = function(_, name, keymaps)
  -- print("Name: "    .. vim.inspect(name))
  -- print("Keymaps: " .. vim.inspect(keymaps))
  local help_text, format = extract_help(keymaps)

  if not help_text then return M end

  local help = {
    _title  = name,
    _text   = help_text,
    _format = format,
  }

  return setmetatable(help, M)
end

M.shown = function ()
  if not WINDOW then
    return false
  end

  if vim.api.nvim_win_get_config(WINDOW).zindex then
    return true
  end

  -- if there is no window reset ID
  --
  WINDOW = nil

  return false

  -- if BUFFER and not fn.bufexists(BUFFER) then
  --   BUFFER = nil
  -- end
  --
  -- 
end

M.show = function (self)
  vim.notify("Showing help")

  if not self._text then return end
  if M:shown() then return end

  create_help_buffer()
  create_help_window()
  construct_help(self)

  show_help(self)
end

M.hide = function()
  if not M:shown() then return end

  hide_help()
end

M.toggle = function (self)
  if not self._text then return end

  if M:shown() then
    M:hide()
  else
    M:show()
  end
end

M.visible = function (self)
  local format    = self._format
  local offset    = self.offset
  local nlines    = #self.help - offset
  local max_lines = format.win_height - 2

  if nlines > max_lines then nlines = max_lines end

  return offset, nlines
end


M.__index = M

return setmetatable(M, {__call = setup})
