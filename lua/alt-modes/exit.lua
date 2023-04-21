local api = vim.api
local fn  = vim.fn

local set_keymap = vim.keymap.set
local del_keymap = vim.keymap.del

local valid_keymap = function(kmap)
  if  kmap.lhs:find("<Plug>") == 1 then
    return false
  else
    return true
  end
end

local clear_buffer_keymaps = function(state)
  for _,kmap in ipairs(
    vim.tbl_filter(
      valid_keymap,
      vim.api.nvim_buf_get_keymap(state.buffer, state.mode)
    )
  ) do
    -- print(string.format("Delete kmap -> Buffer:%d Mode:%s Lhs:%s", kmap.buffer, kmap.mode, kmap.lhs))
    local _,_ pcall(del_keymap, kmap.mode, kmap.lhs, {buffer = kmap.buffer})
  end
end

local restore_buffer_keymaps = function(state)
  local snapshot = state.snapshot

  for _,kmap in ipairs(snapshot) do
    local options = {
      buffer  = kmap.buffer,
      nowait  = kmap.nowait,
      silent  = kmap.silent,
      noremap = kmap.noremap,
    }

    if not kmap.rhs then
      kmap.rhs = kmap.callback
    end

    set_keymap(kmap.mode, kmap.lhs, kmap.rhs, options)
  end
end

local restore_timeout = function(state)
  vim.opt.timeoutlen = state.timeout
end

local exit = function(self, buffer)
  buffer = buffer or api.nvim_get_current_buf()

  local states = self._states[buffer]

  if not states then
    print("There is no state to exit from!")
    return
  end

  local state  = states[#states]

  -- check if buffer exists
  --
  local buffer_info = fn.getbufinfo(buffer)

  if #buffer_info ~= 0 then
    -- vim.notify("Clearing buffer " .. tostring(buffer))
    clear_buffer_keymaps(state)
    restore_buffer_keymaps(state)
  end

  restore_timeout(state)

  local name = state.name

  states[#states] = nil
  if #state == 0 then
    self._states[buffer] = nil
  end

  -- vim.notify('Exited from alt-mode "' .. name .. '"')
end

return exit
