local api = vim.api
local altmodes = require('alt-modes')
local agroup   = 'NvimAltModesFollower'

local unfollow = function(self, action)
  if not self._active then return end

  pcall(api.nvim_del_augroup_by_name, agroup)

  local followers_no = #self._followers

  if action then
    local buffers = self._followers[followers_no].buffers

    for buff,_ in pairs(buffers) do
      action(buff)
    end
  end

  -- vim.notify("No followers pre: " .. tostring(#self._followers))
  self._followers[followers_no] = nil
  -- vim.notify("No followers post: " .. tostring(#self._followers))

  self._active = nil

  altmodes:follow()
end

return unfollow
