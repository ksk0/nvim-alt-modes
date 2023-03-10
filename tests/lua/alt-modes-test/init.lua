-- test/init.lua
local reload = require('alt-modes-test.reload')

local local_sub_test = function (arg_1, arg_2, ...)
  arg_1 = arg_1 or {}
  arg_2 = arg_2 or {}

  local args = {...} or "77"

  arg_1 = {jedan = 1; dva = 2}

  print("A local: " .. vim.inspect(arg_1))
  print("B local: " .. vim.inspect(arg_2))
  print("args:    " .. vim.inspect(args))
end

local local_test = function()
  local a = {}
  local b

  local_sub_test(a, b)

  print("A org: " .. vim.inspect(a))
  print("B org: " .. vim.inspect(b))

  local_sub_test(a, b, {sedam = 7, osam = 8}, {})

end

local arg_test = function(...)

  local args_1 = ...
  local args_2 = {...}

  print("Args: ", vim.inspect(...))
  print("Args: ", vim.inspect({...}))
  print("Args: ", vim.inspect(args_1))
  print("Args: ", vim.inspect(args_2))
  print(" ")

  print("Args:" .. type(...))
  print("Args: ", args_1)
  print("Args: ", args_2)

  for i,arg in ipairs(args_2) do
    print("Arg (" .. i .. ") = " .. vim.inspect(arg))
  end
end

local list_test = function ()
  local list_1 = {"jedan", "dva", "tri", "tri", "dva", "jedan"}
  local list_2 = {"tri", "cetiri", "pet"}
  local list_3 = {"jedan", "cetiri", "sest", "sedam"}
  local list_4
  local list_5

  local list = require("alt-modes.core.list")

  local union_z = list.union()
  local union_0 = list.union(list_1)
  local union_1 = list.union(list_1,list_2)
  local union_2 = list.union(list_1,list_3)
  local union_3 = list.union(list_2,list_3)
  local union_4 = list.union(list_1,list_2,list_3)
  local union_5 = list.union(list_4,list_5)
  local union_6 = list.union(list_4,list_5, list_1)

  local sub_z = list.sub()
  local sub_0 = list.sub({}, list_2)
  local sub_1 = list.sub(list_1, list_2)
  local sub_2 = list.sub(list_1, list_3)
  local sub_3 = list.sub(list_2, list_3)
  local sub_4 = list.sub(list_1, list_2, list_3)
  local sub_5 = list.sub(list_4, list_5)
  local sub_6 = list.sub(list_4, list_5, list_1)
  local sub_7 = list.sub(list_1, list_4, list_5)

  local int_z = list.intersection()
  local int_0 = list.intersection({}, list_2)
  local int_1 = list.intersection(list_1, list_2)
  local int_2 = list.intersection(list_1, list_3)
  local int_3 = list.intersection(list_2, list_3)
  local int_4 = list.intersection(list_1, list_2, list_3)
  local int_5 = list.intersection(list_4, list_5)
  local int_6 = list.intersection(list_4, list_5, list_1)
  local int_7 = list.intersection(list_1, list_4, list_5)

  print("Union:")
  print(vim.inspect(union_z))
  print(vim.inspect(union_0))
  print(vim.inspect(union_1))
  print(vim.inspect(union_2))
  print(vim.inspect(union_3))
  print(vim.inspect(union_4))
  print(vim.inspect(union_5))
  print(vim.inspect(union_6))
  print (" ")
  print ("Substraction:")
  print(vim.inspect(sub_z))
  print(vim.inspect(sub_0))
  print(vim.inspect(sub_1))
  print(vim.inspect(sub_2))
  print(vim.inspect(sub_3))
  print(vim.inspect(sub_4))
  print(vim.inspect(sub_5))
  print(vim.inspect(sub_6))
  print(vim.inspect(sub_7))
  print (" ")
  print ("Intersection:")
  print(vim.inspect(int_z))
  print(vim.inspect(int_0))
  print(vim.inspect(int_1))
  print(vim.inspect(int_2))
  print(vim.inspect(int_3))
  print(vim.inspect(int_4))
  print(vim.inspect(int_5))
  print(vim.inspect(int_6))
  print(vim.inspect(int_7))
end

local nmap_test = function()
  local keymaps = vim.api.nvim_buf_get_keymap(0, 'n')
  print ("Before delete:")
  vim.cmd("nmap <buffer>")
  -- print(vim.inspect(keymaps))

  local deleted
  local lhs = ' li'

  for _,kmap in ipairs(keymaps) do
    if kmap.lhs == lhs then
      deleted = kmap
      vim.api.nvim_buf_del_keymap(0,'n', lhs)
      break
    end
  end

  -- print(vim.inspect(deleted))

  print ("After delete:")
  vim.cmd("nmap <buffer>")

  local example = {                                                                                                                                                                                                                                         
    buffer = 23,
    expr = 0,
    lhs = "gi",
    lhsraw = "gi",
    lnum = 0,
    mode = "n",
    noremap = 1,
    nowait = 0,
    rhs = "<Cmd>lua vim.lsp.buf.implementation()<CR>",
    script = 0,
    sid = -8,
    silent = 1
  }

  local d_buffer = deleted.buffer
  local d_mode   = deleted.mode
  local d_lhs    = deleted.lhs
  local d_rhs    = deleted.rhs

  deleted.buffer = nil
  deleted.mode   = nil
  deleted.lhs    = nil
  deleted.rhs    = nil
  deleted.lhsraw = nil
  deleted.sid    = nil
  deleted.lnum   = nil

  vim.api.nvim_buf_set_keymap(d_buffer, d_mode, d_lhs, d_rhs, deleted)

  print ("After restore:")
  vim.cmd("nmap <buffer>")
end

local combo_test = function()
  local normal = require('alt-modes.native.normal')
  local decouple = require('alt-modes.native.combos')

  -- lhs = 'dva<c-w>jedan<c-x>tri'
  -- print(lhs .. ":" .. vim.inspect(decouple(lhs)))
  --
  -- do return end

  normal = require('alt-modes.native.flatten')(normal)

  local start = os.clock()

  -- for _ = 1,10000 do
  --   for _,kmap in ipairs(normal) do
  --     decouple(kmap)
  --   end
  -- end
  --
  -- for _,kmap in ipairs(normal) do
  --   local combos = decouple(kmap)
  --   print(kmap .. ":" .. vim.inspect(combos))
  -- end

  -- for _ = 1,10000 do
  --   decouple(normal)
  -- end

  for _,combo in ipairs(decouple(normal)) do
    print("Combo:" .. vim.inspect(combo))
  end


  print(string.format("elapsed time: %.2f\n", os.clock() - start))
end

local follower_1 = function ()
  local buf_enter = function (buffer)
    vim.notify("Entered buffer: " .. tostring(buffer))
  end

  local buf_leave = function (buffer)
    vim.notify("Left buffer: " .. tostring(buffer))
  end

  local config = {
    once = false,
    BufEnter = buf_enter,
    BufLeave = buf_leave,
  }

  require('alt-modes'):follow(config)
end

local follower_2 = function ()
  local buf_enter = function (buffer)
    vim.notify("Entered buffer: " .. tostring(buffer), 'error')
  end

  local buf_leave = function (buffer)
    vim.notify("Left buffer: " .. tostring(buffer), 'error')
  end

  local buf_new = function (buffer)
    vim.notify("New buffer: " .. tostring(buffer), 'error')
  end

  local config = {
    once = false,
    BufEnter = {
      init = true,
      action = buf_enter,
    },
    BufNew    = buf_new,
  }

  require('alt-modes'):follow(config)
end

local follower_test = function ()
  if not FOLLOWER_ON then
    follower_1()
    FOLLOWER_ON = 1

  elseif FOLLOWER_ON == 1 then
    follower_2()
    FOLLOWER_ON = 2

  else
    vim.notify("Unfollowing")
    require('alt-modes'):unfollow()

    FOLLOWER_ON = FOLLOWER_ON + 1

    if FOLLOWER_ON == 4 then
      FOLLOWER_ON = nil
    end
  end
end

local run_test = function ()
  -- follower_test()
  -- do return end
  -- combo_test()
  -- do return end

  -- list_test()
  -- local_test()
  -- do return end
  -- arg_test("jedan", "dva", {"tri", "cetiri"})
  -- nmap_test()
  -- do return end

  reload('alt-modes-test.modes')

  local modes = require("alt-modes-test.modes")
  local M = require("alt-modes")

  -- print("M: " .. tostring(M))

  -- print(vim.inspect(modes.testing.keymaps))

  -- local help_1 = require('alt-modes.core.help')("HA HA", modes.help_mode.keymaps)
  -- local help_2 = require('alt-modes.core.help')("HA HA", modes.testing.keymaps)
  -- print(vim.inspect(help))
  -- help_2:show()

  M:add('testing', modes.testing)
  -- print(vim.inspect(M._altmodes['testing']))

  -- print(vim.inspect(M._altmodes['testing']))
  -- LUA_TESTING_ME = true

  M:enter('testing')
end

return run_test
