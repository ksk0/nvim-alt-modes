local list = require("alt-modes.core.list")
local fn = vim.fn

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

  'overlay',

  -- 'shadow',
  -- 'keep',
  'options',
  'keymaps',
}


-- ===============================================
-- helper functions
--
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


-- ===============================================
-- parsing functions
--
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
  altmode.native_mode = altmode.mode or 'n'
  altmode.mode = nil

  local is_ok, error_msg = check_native_mode(altmode.native_mode)

  if not is_ok then
    error(altmode.name .. " (mode definition): " .. error_msg, 0)
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
  for _,scope in ipairs({"native", "global", "buffer"}) do
    altmode[scope] = {
      default = overlay.default[scope],
      shadow  = overlay.shadow[scope],
      keep    = overlay.keep[scope],
    }
  end

  overlay.shadow = nil
  overlay.keep = nil
  overlay.default = nil
end

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

local parse_keymap = function (keymap, altmode)
  keymap.mode = keymap.mode or altmode.native_mode

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
  local keymaps = altmode.keymaps

  if keymaps == nil then
    error(altmode.name .. ' (keymaps definition): no keymaps given', 0)
  end

  if type(keymaps) ~= 'table' then
    error(altmode.name .. ' (keymaps definition): "keymaps" is keymap definition or list of former', 0)
  end

  if not vim.tbl_islist(keymaps) then
    keymaps = {keymaps}
  end

  if vim.tbl_isempty(keymaps) then
    error(altmode.name .. ' (keymaps definition): no keymaps given', 0)
  end


  for _,keymap in pairs(keymaps) do
    keymap = parse_keymap(keymap, altmode)
  end

  table.sort(keymaps,
    function(km1, km2)
      return km1.lhs < km2.lhs
    end
  )

  altmode.keymaps = keymaps
end

local parse_timeout = function (altmode)
  local timeout = altmode.timeout

  if timeout == nil then
    return
  end

  if type(timeout) ~= "number" then
    error(altmode.name .. " (timeout): timeout must be a number!",0)
  end
end

local parse_help = function(altmode)
  if altmode.help == "" then
    return
  end

  local help_keymap = {
    mode = altmode.native_mode,
    lhs = altmode.help,
    rhs = ':lua require("alt-modes"):help()<CR>',
    options = default_keymap_options,
  }

  table.insert(altmode.keymaps, help_keymap)
end

local parse_exit = function(altmode)
  if altmode.exit == "" then
    return
  end

  local exit_keymap = {
    mode = altmode.native_mode,
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

  table.insert(altmode.keymaps, exit_keymap)
end


-- ===============================================
-- worker functions
-- check for redefined altmaps !!! (twice defined)
--
local add_altmode = function (name, altmode)
  altmode.exit = altmode.exit or 'q'
  altmode.help = altmode.help or 'g?'

  altmode.name = altmode.name or name
  altmode.name = altmode.name:upper()

  parse_config_options(altmode)

  parse_native_mode(altmode)
  parse_overlay(altmode)
  parse_keymap_options(altmode)
  parse_keymaps(altmode)
  parse_timeout(altmode)
  parse_help(altmode)
  parse_exit(altmode)
end


-- ===============================================
-- module function
--
local F = function (self, name, altmode)
  local ok,error_msg = pcall(add_altmode, name, altmode)

  if not ok then
    error(error_msg, 2)
  end

  self._altmodes[name] = altmode
end

return F
