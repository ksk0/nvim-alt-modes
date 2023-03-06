local help = require("alt-modes.core.help")
local api  = vim.api


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

  state.help:show()
end

local M = function(self, buffer)
  if help:shown() then
    help:hide()
  else
    show_help(self,buffer)
  end
end

return M
