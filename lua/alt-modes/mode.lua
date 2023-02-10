local api  = vim.api
local fn   = vim.fn

local mode = function(self, buffer)
  buffer = buffer or api.nvim_get_current_buf()

  local states = self._states[buffer]

  if not states then
    return
  end

  local state  = states[#states]

  -- check if buffer exists
  --
  local buffer_info = fn.getbufinfo(buffer)

  if #buffer_info ~= 0 then
    return state.name
  end

  return
end

return mode
