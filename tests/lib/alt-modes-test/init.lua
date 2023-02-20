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
  local list_1 = {"jedan", "dva", "tri"}
  local list_2 = {"tri", "cetiri", "pet"}
  local list_3 = {"jedan", "cetiri", "sest", "sedam"}
  local list_4
  local list_5

  local list = require("alt-modes.core.list")

  local union_1 = list.union(list_1,list_2)
  local union_2 = list.union(list_1,list_3)
  local union_3 = list.union(list_2,list_3)
  local union_4 = list.union(list_1,list_2,list_3)
  local union_5 = list.union(list_4,list_5)
  local union_6 = list.union(list_4,list_5, list_1)

  local sub_1 = list.sub(list_1, list_2)
  local sub_2 = list.sub(list_1, list_3)
  local sub_3 = list.sub(list_2, list_3)
  local sub_4 = list.sub(list_1, list_2, list_3)
  local sub_5 = list.sub(list_4, list_5)
  local sub_6 = list.sub(list_4, list_5, list_1)
  local sub_7 = list.sub(list_1, list_4, list_5)

  local int_1 = list.intersection(list_1, list_2)
  local int_2 = list.intersection(list_1, list_3)
  local int_3 = list.intersection(list_2, list_3)
  local int_4 = list.intersection(list_1, list_2, list_3)
  local int_5 = list.intersection(list_4, list_5)
  local int_6 = list.intersection(list_4, list_5, list_1)
  local int_7 = list.intersection(list_1, list_4, list_5)

  print("Union:")
  print(vim.inspect(union_1))
  print(vim.inspect(union_2))
  print(vim.inspect(union_3))
  print(vim.inspect(union_4))
  print(vim.inspect(union_5))
  print(vim.inspect(union_6))
  print (" ")
  print ("Substraction:")
  print(vim.inspect(sub_1))
  print(vim.inspect(sub_2))
  print(vim.inspect(sub_3))
  print(vim.inspect(sub_4))
  print(vim.inspect(sub_5))
  print(vim.inspect(sub_6))
  print(vim.inspect(sub_7))
  print (" ")
  print ("Intersection:")
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

local run_test = function ()
  list_test()
  -- local_test()
  do return end
  -- arg_test("jedan", "dva", {"tri", "cetiri"})
  -- nmap_test()
  -- do return end

  reload('alt-modes-test.modes')

  local modes = require("alt-modes-test.modes")
  local M = require("alt-modes")

  M:add('testing', modes.testing)
  M:enter('testing')
end

return run_test
