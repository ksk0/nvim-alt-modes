local api = vim.api
local set_keymap = vim.keymap.set
local del_keymap = vim.keymap.del

local list = require("alt-modes.core.list")
local native = require("alt-modes.native")

local native_modes = {
  n = 'normal'
}

local default_options = {
    noremap = true,
    nowait  = false,
    silent  = true,
    expr    = false,
}


-- =====================================================
-- collect current keymaps by "scope":
--   buffer/global/native
--
local valid_keymap = function (k)
  if  k.lhs:find("<Plug>") == 1 then
    return false
  else
    return true
  end
end

local collect_current_keymaps = {}

setmetatable(collect_current_keymaps, {
  __call = function(_, alt_state)
    -- =================================
    -- create list of all current keymaps
    --
    local K = {}

    for _,scope in ipairs({"buffer", "global", "native"}) do
      K[scope] = collect_current_keymaps[scope](alt_state)
    end

    alt_state.current = K

    return K
  end
})

collect_current_keymaps.buffer = function(alt_state)
  local K = {}
  local ordered = {}

  for _,keymap in ipairs(
    vim.tbl_filter(
      valid_keymap,
      vim.api.nvim_buf_get_keymap(alt_state.buffer, alt_state.mode)
    )) do

    K[keymap.lhs] = keymap
    table.insert(ordered,keymap.lhs)
  end

  K._ordered = ordered

  return K
end

collect_current_keymaps.global = function (alt_state)
  local K = {}
  local ordered = {}

  for _,keymap in ipairs(
    vim.tbl_filter(
      valid_keymap,
      vim.api.nvim_get_keymap(alt_state.mode)
    ))do

    K[keymap.lhs] = keymap
    table.insert(ordered,keymap.lhs)
  end

  K._ordered = ordered

  return K
end

collect_current_keymaps.native = function(alt_state)
  local K = {}
  K._ordered = {}

  local ordered =
    native.flatten(
      require("alt-modes.native." .. native_modes[alt_state.mode])
    )

  for _,lhs in ipairs(ordered)do
    K[lhs] = {lhs = lhs}
    table.insert(K._ordered , {lhs = lhs})
  end

  K._ordered = ordered

  return K
end


-- =====================================================
-- Collect keymaps by future state (shadw/keep)
--
local collect_overlay = function(current_keymaps, overlay_keymaps)
  -- each active keymap (buffer/global/native) has defined
  -- "future state" in alternative mode. This state can be:
  --
  --   1) shadowed (ie, existing kmap will be made inactive)
  --   2) kept     (ie, existing kmap will be kept active)
  --
  -- Future state is given as option in alternative mode
  -- definition (future_states variable). Possible option
  -- values are:
  --
  --   1) false   - no keymap will have this state
  --   2) true    - all active keymaps will have this state
  --   3) list    - only keymaps given in list will have this state
  --
  if not overlay_keymaps then
    return {}
  end

  if overlay_keymaps == true then
    return current_keymaps
  end

  local overlay = {}

  for _,lhs in ipairs(overlay_keymaps) do
    overlay[lhs] = true
  end

  return overlay
end

local collect_shadows = function(active_keymaps, overlay)
    return collect_overlay(active_keymaps, overlay.shadow)
end

local collect_keeps = function(active_keymaps, overlay)
    return collect_overlay(active_keymaps, overlay.keep)
end


-- =====================================================
-- Main keymap collection functions
--
local collect_alt_keymaps = function(alt_state)
  local altmode = alt_state.altmode
  local mode = altmode.native_mode
  local keymaps = {}

  for _,keymap in ipairs(
    vim.tbl_filter(
      function(km) return km.mode == mode end,
      altmode.keymaps
    )
  )do
    if type(keymap.lhs) == 'table' then
      for _,lhs in ipairs(keymap.lhs) do
        keymaps[lhs] = {scope = 'active'}
      end
    else
      keymaps[keymap.lhs] = {scope = 'active'}
    end
  end

  return keymaps
end

local collect_kept_keymaps = function(alt_state)
  local K = {}

  for _,scope in ipairs({"buffer", "global", "native"}) do
    local altmode = alt_state.altmode[scope]
    local current = alt_state.current[scope]

    local shadows = collect_shadows(current, altmode)
    local keeps   = collect_keeps(current, altmode)

    local default  = altmode.default

    local kept = {}

    for _,kmap in pairs(current._ordered) do

      if keeps[kmap] then
        kept[kmap] = true
      elseif shadows[kmap] then
        kept[kmap] = false
      else
        kept[kmap] = default
      end
    end

    K[scope] = kept
  end

  alt_state.kept = K

  return K
end


-- =====================================================
-- set alternative buffer keymaps
--
local show_keymap = function (lhs)
  vim.notify("Pressed: " .. lhs)
end

local set_keymaps = {}

set_keymaps.set = function(buffer, kmap)
  kmap.options.buffer = buffer
  set_keymap(kmap.mode, kmap.lhs, kmap.rhs, kmap.options)
end

set_keymaps.keep = function(buffer, kmap)
  set_keymaps.set(buffer, kmap)
end

set_keymaps.shadow = function(buffer, kmap)
  local shadow_kmap = {
    lhs = kmap.lhs,
    rhs = "", -- function() show_keymap(kmap.lhs) end,
    mode = kmap.mode,
    options = default_options,
  }

  set_keymaps.set(buffer, shadow_kmap)
end

set_keymaps.replicate = function(buffer, kmap)
  local replica_kmap = {
    lhs = kmap.lhs,
    rhs = kmap.lhs,
    mode = kmap.mode,
    options = default_options,
  }

  set_keymaps.set(buffer, replica_kmap)
end

set_keymaps.pass = function(_,_)
  -- print("Pass: " .. vim.inspect(kmap))
end


-- =====================================================
-- MAIN functions
--
local init_alt_state = function(self, name, buffer)
  local altmode = self._altmodes[name]

  if not altmode then
    local msg = string.format("(entering alternative mode): Alt mode '%s' does not exist!", name)
    error(msg,3)
  end

  if not altmode then
    return
  end

  buffer = buffer or api.nvim_get_current_buf()

  local alt_state = {}

  alt_state.name = altmode.name
  alt_state.mode = altmode.native_mode
  alt_state.buffer = buffer
  alt_state.altmode = altmode

  self._states[buffer] = self._states[buffer] or {}
  table.insert(self._states[buffer], alt_state)

  return alt_state
end

local get_keymap_snapshot = function(alt_state)
  alt_state.snapshot = vim.tbl_filter(
    valid_keymap,
    vim.api.nvim_buf_get_keymap(alt_state.buffer, alt_state.mode)
  )
end

local get_keymap_actions = function (alt_state)
  -- =====================================================
  --
  --              (1) OK    (2) OK      (3) OK      (4) OK      (5) !!    (6) !!       
  --   -----------------------------------------------------------------------------
  --   A -------- [A]       [ ]         [ ]         [ ]         [A]       [ ]
  --   B -------- [S]       [S]         [S]         [S]         [S]       [S]
  --   G -------- [S]       [S]         [S]         [K]         [S]       [K]
  --   N -------- [S]       [S]         [K]         [S]         [K]       [K]
  --   --------------------------------------------------------------------------------
  --   ACTION:    set       shadow      replicate   clear       set       clear
  --
  --   a) collect keymaps
  --   b) collect altmaps
  --   c) collect keeps
  --   d) collect shadows
  --
  --   e) foreach active keymap:
  --      *) if in altmaps set altmap
  --      *) if in buffer keeps keep keymap
  --      *) if in global keeps delete buffer keymap
  --      *) if in native keeps replicate keymap
  --      *) shadow altmap
  --

  -- =================================
  -- collect keymaps
  --
  local alt_keymaps     = collect_alt_keymaps(alt_state)
  local current_keymaps = collect_current_keymaps(alt_state)
  local kept_keymaps    = collect_kept_keymaps(alt_state)

  local kept_buffer  = kept_keymaps.buffer
  local kept_global  = kept_keymaps.global
  local kept_native  = kept_keymaps.native

  local current_buffer = current_keymaps.buffer
  local current_global = current_keymaps.global
  local current_native = current_keymaps.native

  local current_all = list.union(
    current_buffer._ordered,
    current_global._ordered,
    current_native._ordered
  )

  -- =================================
  -- define what to do with active
  -- keymaps.
  --
  local actions = {}
  local mode = alt_state.mode

  for _,lhs in ipairs(current_all) do
    -- check only kmaps which will not be activated
    --
    if not alt_keymaps[lhs] then
      -- keep buffer kmap
      --
      if kept_buffer[lhs] then
        table.insert(actions, {action = 'keep', kmap = current_buffer[lhs]})

      -- to keep global kmap, just pass through buffer
      --
      elseif kept_global[lhs] then
        table.insert(actions, {action = 'pass', kmap = {lhs = lhs, mode = mode}})

      elseif kept_native[lhs] then
        table.insert(actions, {action = 'replicate', kmap = {lhs = lhs, mode = mode}})

      -- if not in "keeps" shadow this keymap
      --
      else
        table.insert(actions, {action = 'shadow', kmap = {lhs = lhs, mode = mode}})
      end
    end
  end

  -- ====================================
  -- sort and add alternative keymaps (
  -- these have been ingnored in shadow/
  -- keep)
  --
  for _,kmap in ipairs(alt_state.altmode.keymaps) do
    table.insert(actions, {action = 'set', kmap = kmap})
  end

  alt_state.actions = actions
end

local clear_buffer_keymaps = function(alt_state)

  for _,kmap in ipairs(alt_state.snapshot) do
    local _,_ pcall(del_keymap, kmap.mode, kmap.lhs, {buffer = kmap.buffer})
  end
end

local set_buffer_keymaps = function(alt_state)
  local buffer = alt_state.buffer

  for _,action in ipairs(alt_state.actions) do
    set_keymaps[action.action](buffer, action.kmap)
  end
end

local set_timeout = function(alt_state)
  alt_state.timeout = vim.opt.timeoutlen._value

  local timeout = alt_state.altmode.timeout

  if not timeout then
    return
  end

  vim.opt.timeoutlen = timeout
end


local enter = function (self, name, buffer)
  local alt_state = init_alt_state(self, name, buffer)

  get_keymap_snapshot(alt_state)
  get_keymap_actions(alt_state)
  clear_buffer_keymaps(alt_state)
  set_buffer_keymaps(alt_state)
  set_timeout(alt_state)

  alt_state.current = nil
  alt_state.actions = nil
  alt_state.kept    = nil

  vim.notify("Entered mode: " .. name)
end

return enter