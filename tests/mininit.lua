-- =======================================================
-- Packer should be present
--
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- =======================================================
-- Get directory where this script is located
--
local function script_path()
  local iswin = package.config:sub(1, 1) == '\\'
  local path  = debug.getinfo(2, 'S').source:sub(2)
  local separator =  '\\' and iswin or  '/'

  if iswin then
    path = path:gsub('/', '\\')
  end

  return path:match('(.*' .. separator .. ')')
end

-- =======================================================
-- Get directory where this plugin is located
--
local plugin_root = script_path():match('(.-)/([^/]+/)$')

-- =======================================================
-- load this plugin
--
return packer.startup(function(use)
  use(plugin_root)
end)
