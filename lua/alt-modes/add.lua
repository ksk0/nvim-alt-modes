local list = require("alt-modes.core.list")
local help = require("alt-modes.core.help")

local fn   = vim.fn
local map  = vim.tbl_map

-- ===============================================
-- valid and defaulte values
--
local valid_modes = "nv"

local default_keymap_options = {
    noremap = true,
    nowait  = true,
    silent  = true,
    expr    = false,
}

local valid_config_options = {
  'name',
  'mode',
  'exit',
  'help',
  'timeout',
  'status',

  'overlay',
  'options',
  'keymaps',
}


-- ===============================================
-- helper functions
--
local max = function(item_list)
  if not item_list then
    return
  end

  local sorted = vim.deepcopy(item_list)
  table.sort(sorted)
  return sorted[1]
end

local function flatten_keymap_tree(keymap_tree)
  if type (keymap_tree) == "boolean" then
    return keymap_tree
  end

  return require("alt-modes.native.flatten")(keymap_tree)
end


-- ===============================================
-- check functions
--
local function check_keymap_tree_value(value)

  if (type(value) == "string") then
    return true
  end

  if (type(value) == "table") then
    if vim.tbl_isempty(value) then
      return false
    end

    for _,content in pairs(value) do
      if not check_keymap_tree_value(content) then
        return false
      end
    end

    return true
  end
end

local check_native_mode = function (mode)
  mode = mode or 'n'

  local invalids  = list.sub({mode}, vim.split(valid_modes,""))

  if not vim.tbl_isempty(invalids) then
    return false, '"' .. mode .. '" is not valid native mode!'
  end

  return true, mode
end

local check_options = function (options)
  options = options or {}
  options = type(options) == 'table' and options or {[options] = true}

  -- ==========================================
  -- if options are mix of table values and list 
  -- convert list to table values
  --
  for i,option in ipairs(options) do
    options[option] = true
    options[i] = nil
  end

  -- ==========================================
  -- if desc is present in options, ignore it
  --
  local opt_keys = list.sub(vim.tbl_keys(options), {"desc", "buffer"})
  local invalids = list.sub(opt_keys, vim.tbl_keys(default_keymap_options))

  if not vim.tbl_isempty(invalids) then
    local error_msg = '"' .. fn.join(invalids, '", "') .. '"'
    return false, "Invalid option(s): " .. error_msg
  end

  for _,key in pairs(opt_keys) do
    local value = options[key]

    if not (value == true or value == false) then
     return false, 'Option "' .. key .. '" should have boolean value!'
    end
  end

  return true, options
end

local check_keymaps = function(altmode)
  local keymaps = altmode.keymaps

  if keymaps == nil then
    error(altmode.name .. ' (keymaps definition): no keymaps given', 0)
  end

  if type(keymaps) ~= 'table' then
    error(altmode.name .. ' (keymaps definition): "keymaps" is keymap definition or list of former', 0)
  end

  if vim.tbl_isempty(keymaps) then
    error(altmode.name .. ' (keymaps definition): no keymaps given', 0)
  end

  if not vim.tbl_islist(keymaps) then
    keymaps = {keymaps}
  end

  altmode.keymaps = keymaps
end


-- ===============================================
-- parsing functions
--
local parse_name = function (altmode, name)
  altmode.name = altmode.name or name
  altmode.name = altmode.name:upper()
end

local parse_config_options = function(altmode)
  local params = vim.tbl_keys(altmode)
  local invalides = list.sub(params, valid_config_options)

  if #invalides ~= 0 then
    local invalid_list = '"' .. fn.join(invalides, '", "') .. '"'
    local msg = " Invalid config option(s): " .. invalid_list
    error(altmode.name .. msg, 0)
  end
end

local parse_native_mode = function(altmode)
  altmode._mode = altmode.mode or 'n'
  altmode.mode = nil

  local is_ok, error_msg = check_native_mode(altmode._mode)

  if not is_ok then
    error(altmode.name .. " (mode definition): " .. error_msg, 0)
  end
end

local parse_timeout = function (altmode)
  altmode._timeout = altmode.timeout
  altmode.timeout  = nil

  if altmode._timeout == nil then
    return
  end

  if type(altmode._timeout) ~= "number" then
    error(altmode.name .. " (timeout): timeout must be a number!",0)
  end
end

local parse_status = function (altmode)
  altmode._status = altmode.status
  altmode.status  = nil

  if altmode._status == nil then
    local status = altmode.name
    altmode._status = function() return status end
    return
  end

  if type(altmode._status) ~= "function" then
    error(altmode.name .. " (status): status must be a function!",0)
  end
end


-- ===============================================
-- overlay parsing functions
--
local parse_overlay_defaults = function (altmode)
  altmode.overlay.default = altmode.overlay.default or {}

  local defaults = altmode.overlay.default
  local default_scopes = vim.tbl_keys(defaults)
  local invalides = list.sub(default_scopes, {"native", "global", "buffer"})

  if #invalides ~= 0 then
    local invalid_list = '"' .. fn.join(invalides, '", "') .. '"'
    local msg = " (overlay defaults): Invalid scope(s): " .. invalid_list
    error(altmode.name .. msg, 0)
  end

  for _,scope in ipairs({"native", "global", "buffer"}) do
    local default = defaults[scope]

    if not default or default == 'shadow' then
      defaults[scope] = false
    elseif default == 'keep' then
      defaults[scope] = true
    else
      local msg = " (overlay defaults): Invalid scope value: " .. tostring(default)
      error(altmode.name .. msg, 0)
    end
  end
end

local parse_overlay_mode = function(altmode, mode)
  local overlay = altmode.overlay[mode] or {}

  overlay = type(overlay) == 'table' and overlay or {[overlay] = true}

  local invalid = list.sub(vim.tbl_keys(overlay), {"native", "global", "buffer"})
  local msg
  local format

  if not vim.tbl_isempty(invalid) then
    local invalids = '"' .. fn.join(invalid, '", "') .. '"'

    format = "%s: Invalid %s level(s): %s"
    msg = format:format(altmode.name, mode, invalids)

    error (msg,0)
  end

  for key,value in pairs(overlay) do
    if not (value == true or value == false) then
      if not check_keymap_tree_value(value) then
        format = '%s: %s "%s" should have value of: boolean, string or table of strings (nested)!'
        msg = format:format(altmode.name, mode, key)

        error (msg,0)
      end
    end
  end

  local defaults = altmode.overlay.default

  for _,scope in ipairs({"native", "global", "buffer"}) do
    if overlay[scope] == nil then
      if mode == 'keep' then
        overlay[scope] = defaults[scope]
      else
        overlay[scope] = not defaults[scope]
      end
    else
      overlay[scope] = flatten_keymap_tree(overlay[scope])
    end
  end

  altmode.overlay[mode] = overlay
end

local parse_overlay_shadows = function (altmode)
  parse_overlay_mode(altmode, 'shadow')
end

local parse_overlay_keeps = function (altmode)
  parse_overlay_mode(altmode, 'keep')
end

local parse_overlay = function(altmode)
  altmode.overlay = altmode.overlay or {}

  local options = vim.tbl_keys(altmode.overlay)
  local invalides = list.sub(options, {"default", "shadow", "keep"})

  if #invalides ~= 0 then
    local invalid_list = '"' .. fn.join(invalides, '", "') .. '"'
    local msg = " (overlay): Invalid option(s): " .. invalid_list
    error(altmode.name .. msg, 0)
  end


  parse_overlay_defaults(altmode)
  parse_overlay_shadows(altmode)
  parse_overlay_keeps(altmode)

  -- ======================================
  -- if keep is "true", shadowing can't be
  -- done. Raise error!
  --
  local overlay = altmode.overlay
  for _,scope in ipairs({"native", "global", "buffer"}) do
    if type(overlay.keep[scope]) ~= 'table' and overlay.shadow[scope] == overlay.keep[scope] then
      local msg = " (keep/shadow): can't simultaniously keep and shadow %s keymaps"
      error(altmode.name .. msg:format(scope),0)
    end
  end

  -- ======================================
  -- Group shadow/keeps by scope
  local _overlay = {}
  for _,scope in ipairs({"native", "global", "buffer"}) do
    _overlay[scope] = {
      default = overlay.default[scope],
      shadow  = overlay.shadow[scope],
      keep    = overlay.keep[scope],
    }
  end

  altmode._overlay = _overlay
  altmode.overlay  = nil
end


-- ===============================================
-- keymap parsing functions
--
local parse_keymap_options = function (altmode)
  local is_ok, options = check_options(altmode.options)

  if not is_ok then
    error(altmode.name .. " (mode definition): " .. options, 0)
  end

  for key,value in pairs(default_keymap_options) do
    if options[key] == nil then
      options[key] = value
    end
  end

  altmode.options = options
end

local parse_rhs = function(rhs)
  if type(rhs) ~= 'string' then
    return rhs
  end

  rhs = rhs:gsub("^:*", "")
  rhs = rhs:gsub("^<[cC][mM][dD]>", "")
  rhs = rhs:gsub("<[cC][rR]>$", "")
  rhs = ":" .. rhs .. "<CR>"

  return rhs
end

local function parse_keymap(altmode, keymap)
  if vim.tbl_islist(keymap) then
    for _,kmap in ipairs(keymap) do
      parse_keymap(altmode, kmap)
    end

    return
  end

  keymap.mode = keymap.mode or altmode._mode

  local mode_ok, error_msg = check_native_mode(keymap.mode)

  if not mode_ok then
    error(altmode.name .. " (keymaps definition): " .. error_msg, 0)
  end

  if keymap.lhs == nil then
    error(altmode.name .. ' (keymaps definition): "lhs" value must be given!', 0)
  end

  if keymap.rhs == nil then
    error(altmode.name .. ' (keymaps definition): "rhs" value must be given!', 0)
  end

  local options_ok, options = check_options(keymap.options)

  if not options_ok then
    error(altmode.name .. " (keymaps definition): " .. options, 0)
  end

  -- ==========================================
  -- Options for single keymap are defined with
  -- following precedance:
  --
  --   1. option directly given in keymap
  --   2. option defined in "keymap.options" table
  --   3. option defined in "altmode.options" table
  --   4. default option value
  --
  for opt,value in pairs(altmode.options) do
    -- if option is given directly in "keymap"
    -- use that.
    --
    if keymap[opt] ~= nil then
      options[opt] = keymap[opt]
      keymap[opt] = nil

    -- if option is not defined, use one given
    -- in "altmode.options" table
    --
    elseif not options[opt] then
      options[opt] = value
    end
  end

  options_ok, options = check_options(options)

  if not options_ok then
    error(altmode.name .. " (keymaps definition): " .. options, 0)
  end

  -- =======================================
  -- move description from keymap to options
  -- for later use
  --
  if keymap.desc then
    options.desc = keymap.desc
    keymap.desc = nil
  end

  keymap.options = options

  local invalids = list.sub(vim.tbl_keys(keymap), {"mode", "lhs", "rhs", "desc", "options"})

  if not vim.tbl_isempty(invalids) then
    local msg = '"' .. fn.join(invalids, '", "') .. '"'
    error(altmode.name .. ' (keymaps definition): invalid parameter(s): ' .. msg, 0)
  end

  keymap.rhs = parse_rhs(keymap.rhs)
end

local parse_keymaps = function (altmode)
  check_keymaps(altmode)

  local keymaps = altmode.keymaps

  for _,keymap in pairs(keymaps) do
    parse_keymap(altmode, keymap)
  end

  altmode._keymaps = fn.flatten(keymaps)

  table.sort(altmode._keymaps,
    function(km_1, km_2)
      return km_1.lhs < km_2.lhs
      -- return km_1.lhs > km_2.lhs
    end
  )
end

local parse_help_keymap = function(altmode)
  if altmode.help == "" then
    return
  end

  altmode.help = altmode.help or 'g?'

  local help_keymap = {
    mode = altmode._mode,
    lhs = altmode.help,
    rhs = ':lua require("alt-modes"):help()<CR>',
    options = default_keymap_options,
  }

  table.insert(altmode._keymaps, help_keymap)
end

local parse_exit_keymap = function(altmode)
  if altmode.exit == "" then
    return
  end

  local exit_keymap = {
    mode = altmode._mode,
    lhs = altmode.exit,
    rhs = ':lua require("alt-modes"):exit()<CR>',
    options = {
      noremap = true,
      nowait  = false,
      silent  = true,
      expr    = false,
      desc    = "Exit alt-mode " .. altmode.name,
    }
  }

  table.insert(altmode._keymaps, exit_keymap)
end


-- ===============================================
-- help parsing functions
--
local function parse_keymaps_help (altmode)
  -- print(vim.inspect(altmode.name))
  -- print(vim.inspect(altmode.keymaps))
  altmode._help = help(altmode.name, altmode.keymaps)
  -- print(vim.inspect(altmode._help))
end


-- ===============================================
-- worker functions
-- check for redefined altmaps !!! (twice defined)
--
local add_altmode = function (name, altmode)
  parse_name(altmode, name)

  parse_config_options(altmode)       -- check validity of config options

  parse_native_mode(altmode)          -- check native mode
  parse_overlay(altmode)              -- check overlay config
  parse_keymap_options(altmode)       -- check default options for keymaps
  parse_keymaps(altmode)              -- parse keymap list
  parse_keymaps_help(altmode)         -- create_help_structure

  parse_timeout(altmode)              -- check timeout value
  parse_status(altmode)               -- check status function
  parse_help_keymap(altmode)          -- parse help keymap
  parse_exit_keymap(altmode)          -- parse exit keymap

  altmode._name   = altmode.name
  altmode.name    = nil
  altmode.exit    = nil
  altmode.help    = nil
  altmode.options = nil
  altmode.keymaps = nil
end


-- ===============================================
-- module function
--
local add = function (self, name, altmode)
  local ok,error_msg = pcall(add_altmode, name, altmode)

  if not ok then
    error(error_msg, 2)
  end

  self._altmodes[name] = altmode
end

return add
