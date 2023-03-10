local api = vim.api
local keymap_set = vim.keymap.set
local keymap_del = vim.keymap.del

local list = require("alt-modes.core.list")
local native = require("alt-modes.native")

local native_modes = {
  n = 'normal'
}

local replica_options = {
    noremap = true,
    nowait  = true,
    silent  = false,
    expr    = false,
}

local blocked_options = {
    noremap = true,
    nowait  = false,
    silent  = true,
    expr    = false,
}


-- =====================================================
-- collect active keymaps by "scope":
--   buffer/global/native
--
local valid_keymap = function (k)
  if  k.lhs:find("<Plug>") == 1 then
    return false
  else
    return true
  end
end

local collect_active_keymaps = {}

setmetatable(collect_active_keymaps, {
  __call = function(_, alt_state)
    -- =================================
    -- create list of all active keymaps
    --
    local K = {}

    for _,scope in ipairs({"buffer", "global", "native"}) do
      K[scope] = collect_active_keymaps[scope](alt_state)
    end

    alt_state.active = K

    return K
  end
})

collect_active_keymaps.buffer = function(alt_state)
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

collect_active_keymaps.global = function (alt_state)
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

collect_active_keymaps.native = function(alt_state)
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
-- Collect keymaps by future state (blocked/kept)
--
local collect_overlay = function(active_keymaps, overlay_keymaps)
  -- each active keymap (buffer/global/native) has defined
  -- "future state" in alternative mode. This state can be:
  --
  --   1) blocked  (ie, existing kmap will be made inactive)
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
    return active_keymaps
  end

  local overlay = {}

  for _,lhs in ipairs(overlay_keymaps) do
    overlay[lhs] = true
  end

  return overlay
end

local collect_blocked = function(active_keymaps, overlay)
    return collect_overlay(active_keymaps, overlay.blocked)
end

local collect_kept = function(active_keymaps, overlay)
    return collect_overlay(active_keymaps, overlay.kept)
end


-- =====================================================
-- Main keymap collection functions
--
local collect_altmode_keymaps = function(alt_state)
  local mode = alt_state.mode
  local keymaps = {}

  for _,keymap in ipairs(
    vim.tbl_filter(
      function(km) return km.mode == mode end,
      alt_state.keymaps
    )
  )do
    if type(keymap.lhs) == 'table' then
      for _,lhs in ipairs(keymap.lhs) do
        keymaps[lhs] = true
      end
    else
      keymaps[keymap.lhs] = true
    end
  end

  return keymaps
end

local collect_kept_keymaps = function(alt_state)
  local K = {}

  for _,scope in ipairs({"buffer", "global", "native"}) do
    local overlay = alt_state.overlay[scope]
    local active  = alt_state.active[scope]

    local blocked = collect_blocked (active, overlay)
    local kept    = collect_kept(active, overlay)
    local default = overlay.default

    local keep = {}

    for _,kmap in pairs(active._ordered) do

      if kept[kmap] then
        keep[kmap] = true
      elseif blocked[kmap] then
        keep[kmap] = false
      else
        keep[kmap] = default
      end
    end

    K[scope] = keep
  end

  alt_state.kept = K

  return K
end

local collect_keymaps = function(alt_state)
end


-- =====================================================
-- keymap actions
--
local get_buffer_actions = function (alt_state)
  -- =====================================================
  --
  --              (1) OK    (2) OK      (3) OK      (4) OK      (5) !!    (6) !!       
  --   -----------------------------------------------------------------------------
  --   A -------- [A]       [ ]         [ ]         [ ]         [A]       [ ]
  --   B -------- [B]       [B]         [B]         [B]         [B]       [B]
  --   G -------- [B]       [B]         [B]         [K]         [B]       [K]
  --   N -------- [B]       [B]         [K]         [B]         [K]       [K]
  --   --------------------------------------------------------------------------------
  --   ACTION:    set       blocked     replicate   clear       set       clear
  --
  --   a) collect active keymaps
  --   b) collect altmaps
  --   c) collect kept
  --   d) collect blocked
  --
  --   e) foreach active keymap:
  --      *) if in altmaps set altmap
  --      *) if in buffer keeps kept keymap
  --      *) if in global keeps delete buffer keymap
  --      *) if in native keeps replicate keymap
  --      *) blocked altmap
  --

  -- =================================
  -- collect keymaps
  --
  local altmode_keymaps = collect_altmode_keymaps(alt_state)
  local active_keymaps  = collect_active_keymaps(alt_state)
  local kept_keymaps    = collect_kept_keymaps(alt_state)

  local kept_buffer   = kept_keymaps.buffer
  local kept_global   = kept_keymaps.global
  local kept_native   = kept_keymaps.native

  local active_buffer = active_keymaps.buffer
  local active_global = active_keymaps.global
  local active_native = active_keymaps.native

  local all_active = list.union(
    active_buffer._ordered,
    active_global._ordered,
    active_native._ordered
  )

  -- =================================
  -- define what to do with active
  -- keymaps.
  --
  local actions = {}
  local blocked = {}
  local natives = {}
  local mode = alt_state.mode

  for _,lhs in ipairs(all_active) do
    -- check only kmaps which will not be activated
    --
    if not altmode_keymaps[lhs] then
      -- kept buffer kmap
      --
      if kept_buffer[lhs] then
        table.insert(actions, {action = 'keep', kmap = active_buffer[lhs]})

      -- to keep global kmap, just pass through buffer
      --
      elseif kept_global[lhs] then
        table.insert(actions, {action = 'pass', kmap = {lhs = lhs, mode = mode}})

      elseif kept_native[lhs] then
        if active_global[lhs] then
          table.insert(actions, {action = 'replicate', kmap = {lhs = lhs, mode = mode}})
        else
          local action = {action = 'native', kmap = {lhs = lhs, mode = mode}}

          table.insert(actions, action)
          table.insert(natives, lhs)
        end

      -- if not in "kept" block this keymap
      --
      else
        local action = {action = 'block', kmap = {lhs = lhs, mode = mode}}

        table.insert(actions, action)
        blocked[lhs] = action
      end
    end
  end

  local blocked_keys = vim.tbl_keys(blocked)
  local lhs_combos   = list.union(vim.tbl_flatten(native.combos(natives)))
  local replicate    = list.intersection(blocked_keys, lhs_combos)

  for _,lhs in ipairs(replicate) do
    blocked[lhs].action = 'replicate'
  end

  -- ========================================
  -- sort and add alternative keymaps ( these
  -- have been ingnored in block/kept)
  --
  for _,kmap in ipairs(alt_state.keymaps) do
    table.insert(actions, {action = 'set', kmap = kmap})
  end

  alt_state.actions = actions
end

local get_keymap_actions = function (alt_state)
  get_buffer_actions(alt_state)
end


-- =====================================================
-- set alternative buffer keymaps
--
local show_keymap = function (lhs)
  -- do return end
  vim.notify("Blocked: " .. lhs)
end

local set_keymap = setmetatable({}, {
  __call = function (_,buffer, kmap)
    kmap.options.buffer = buffer
    keymap_set(kmap.mode, kmap.lhs, kmap.rhs, kmap.options)
  end
})

set_keymap.set = function(buffer, kmap)
  -- print('Set: ' .. kmap.lhs .. " action: " .. tostring(kmap.rhs))
  set_keymap(buffer, kmap)
end

set_keymap.keep = function(buffer, kmap)
  set_keymap(buffer, kmap)
end

set_keymap.block = function(buffer, kmap)
  local blocked_kmap = {
    lhs = kmap.lhs,
    rhs = function() show_keymap(kmap.lhs) end,
    mode = kmap.mode,
    options = blocked_options,
  }

  set_keymap(buffer, blocked_kmap)
end

set_keymap.replicate = function(buffer, kmap)
  local replica_kmap = {
    lhs = kmap.lhs,
    rhs = kmap.lhs,
    mode = kmap.mode,
    options = replica_options,
  }

  -- print("Replicating: "  .. vim.inspect(replica_kmap))

  set_keymap(buffer, replica_kmap)
end

set_keymap.native = function(_,_)
  -- print("Pass: " .. vim.inspect(kmap))
end

set_keymap.pass = function(_,_)
  -- print("Pass: " .. vim.inspect(kmap))
end

local clear_buffer_keymaps = function(alt_state)
  for _,kmap in ipairs(alt_state.snapshot) do
    local _,_ pcall(keymap_del, kmap.mode, kmap.lhs, {buffer = kmap.buffer})
  end
end

local set_buffer_keymaps = function(alt_state)
  clear_buffer_keymaps(alt_state)

  local buffer = alt_state.buffer

  for _,action in ipairs(alt_state.actions) do
    -- print(action.action, action.kmap.lhs)
    set_keymap[action.action](buffer, action.kmap)
  end
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

  buffer = buffer or api.nvim_get_current_buf()

  local alt_state = {}

  alt_state.buffer  = buffer
  alt_state.name    = altmode._name       -- OK
  alt_state.mode    = altmode._mode       -- OK
  alt_state.timeout = altmode._timeout    -- OK
  alt_state.keymaps = altmode._keymaps    -- OK
  alt_state.overlay = altmode._overlay    -- OK
  alt_state.help    = altmode._help       -- OK
  alt_state.status  = altmode._status     -- OK

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

local set_timeout = function(alt_state)
  local timeout = alt_state.timeout

  if not timeout then
    return
  end

  alt_state.timeout = vim.opt.timeoutlen._value

  vim.opt.timeoutlen = timeout
end


local enter = function (self, name, buffer)
  local alt_state = init_alt_state(self, name, buffer)

  get_keymap_snapshot(alt_state)
  get_keymap_actions(alt_state)
  set_buffer_keymaps(alt_state)
  set_timeout(alt_state)

  alt_state.current = nil
  alt_state.actions = nil
  alt_state.kept    = nil

  vim.notify("Entered mode: " .. name)
end

return enter
