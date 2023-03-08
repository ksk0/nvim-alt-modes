local list = require('project-tools.core.list')
local fn = vim.fn
local api = vim.api
local agroup = 'NvimAltModesFollower'

local global_options = {"once", "init", "filter"}
local event_options  = {"once", "init", "filter", "action"}

-- ============================================
-- autocmd creation
--
local create_agroup = function ()
  return api.nvim_create_augroup(agroup,{})
end

local delete_agroup = function ()
  pcall(api.nvim_del_augroup_by_name, agroup)
end

local create_autocmd = function(event, pattern, callback, gid)
  gid  = gid or create_agroup()

  local options = {
    group = gid,
    pattern = pattern,
    callback = callback,
  }

  api.nvim_create_autocmd(event, options)
end

local delete_autocmd = function (event, pattern)
  local options = {
    group = agroup,
    event = event,
    pattern = pattern,
  }

  local cmds = api.nvim_get_autocmds(options)

  if #cmds ~= 0 then
    pcall(api.nvim_del_autocmd, cmds[1].id)
  end
end


-- ============================================
-- parse and check options
--
local parse_event = function(event, options)

  local void = function () end
  local ok,_ = pcall(create_autocmd, event, 'imposible-pattern', void)

  if not ok then
    error('follow [' .. event .. ']: is not valid event', 5)
  else
    delete_autocmd(event, 'imposible-pattern')
  end

  local e_options = options[event]

  if type(e_options) ~= 'table' and type(e_options) ~= 'function' then
    error('follow [' .. event .. ']: must be function or table of options', 5)
  end

  if type(e_options) == 'function' then
    options[event] = {
      action = e_options,
      once = options.once,
      init = options.init,
      filter = options.filter,
    }

    return
  end

  local opts = vim.tbl_keys(e_options)
  local invalid = list.sub(opts, event_options)

  if #invalid ~= 0 then
    local invalids = '"' .. fn.join(invalid, '", "') .. '"'
    error('follow [' .. event .. ']: invalid option(s): ' .. invalids, 5)
  end

  if e_options.action == nil then
    error('follow [' .. event .. ']: "action" must be given', 5)
  end

  if type(e_options.action) ~= 'function' then
    error('follow [' .. event .. ']: "action" must be function', 5)
  end

  if e_options.once ~= nil and type(e_options.once) ~= 'boolean' then
    error('follow [' .. event .. ']: "once" option must be boolean', 5)
  end

  if e_options.init ~= nil and type(e_options.init) ~= 'boolean' then
    error('follow [' .. event .. ']: "init" option must be boolean', 5)
  end

  if e_options.filter ~= nil and type(e_options.filter) ~= 'function' then
    error('follow [' .. event .. ']: "filter" option must be function', 5)
  end

  if e_options.once == nil then
    e_options.once = options.once
  end

  if e_options.init == nil then
    e_options.init = options.init
  end

  if e_options.filter == nil then
    e_options.filter = options.filter
  end
end

local check_options = function(options)
  if type(options) ~= 'table' then
    error('follow: Options must be table of options',4)
  end

  local opts = vim.tbl_keys(options)
  local events = list.sub(opts, global_options)

  if #events == 0 then
    error('follow: No events were given!',4)
  end

  if options.once ~= nil and type(options.once) ~= 'boolean' then
    error('follow: "once" option must be boolean', 5)
  end

  if options.filter ~= nil and type(options.filter) ~= 'function' then
    error('follow: "filter" option must be function', 5)
  end

  if options.init ~= nil and type(options.init) ~= 'boolean' then
    error('follow: "init" option must be boolean', 5)
  end
end

local parse_options = function(options)
  local follower = vim.deepcopy(options)

  check_options(follower)

  if follower.once == nil then
    follower.once = true
  end

  if follower.init == nil then
    follower.init = false
  end

  if follower.filter == nil then
    follower.filter = function () return true end
  end

  local opts = vim.tbl_keys(follower)
  local events = list.sub(opts, global_options)

  for _,event in ipairs(events) do
    parse_event(event, follower)
  end

  follower.init     = nil
  follower.filter   = nil
  follower.once     = nil
  follower.buffers  = {}

  return follower
end


-- ============================================
-- worker functions
--
local event_worker = function(options)

  return function()
    local buffer = api.nvim_get_current_buf()

    if not options.filter(buffer) then return end

    options._buffers[buffer] = true

    if options._done[buffer] then return end

    options.action(buffer)

    if options.once then
      options._done[buffer] = true
    end
  end
end


-- ============================================
-- main functions
--
local init_folower = function(follower)
  delete_agroup()

  local gid = create_agroup()
  local events = vim.tbl_keys(follower)

  events = list.sub(events, {"buffers"})

  for _, event in ipairs(events) do
    local e_options = follower[event]

    e_options._buffers = follower.buffers
    e_options._done = {}

    local worker = event_worker(e_options)

    create_autocmd(event, '*', worker, gid)

    if e_options.init then
      -- vim.notify("Calling worker for: " .. event)
      worker()
    end
  end
end

local follow = function(self, options)
  local follower

  if options then
    follower = parse_options(options)
    table.insert(self._followers, follower)
    -- vim.notify("New set of followers", "warn")

  elseif self._active then
    -- vim.notify("Follower already active", "warn")
    return

  elseif #self._followers == 0 then
    -- vim.notify("Ended following", "error")
    return

  else
    -- vim.notify("activating last follower from stack", "warn")
    follower = self._followers[#self._followers]

  end

  init_folower(follower)

  self._active = true
end

return follow
