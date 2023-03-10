-- lazy load alt-modes
--
local M = {}

M._altmodes  = {}   -- alternative modes are stored here
M._states    = {}   -- list of buffer states (active alt modes)
M._followers = {}   -- list of buffer states (active alt modes)

M.get = function (self, name)
  return self._altmodes[name]
end


return setmetatable(M, {
  __index = function(t, k)
    local module = string.format("alt-modes.%s", k)
    local ok, val = pcall(require, module)

    if ok then
      rawset(t, k, val)
    else
      val = nil
    end

    return val
  end,
})
