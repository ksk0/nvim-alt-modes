-- test/init.lua
local reload = require('alt-modes.core.reload')

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

  local list = require("alt-modes.core.list")

  local union_1 = list.union(list_1,list_2)
  local union_2 = list.union(list_1,list_3)
  local union_3 = list.union(list_2,list_3)
  local union_4 = list.union(list_1,list_2,list_3)

  local sub_1 = list.sub(list_1, list_2)
  local sub_2 = list.sub(list_1, list_3)
  local sub_3 = list.sub(list_2, list_3)
  local sub_4 = list.sub(list_1, list_2, list_3)

  local int_1 = list.intersection(list_1, list_2)
  local int_2 = list.intersection(list_1, list_3)
  local int_3 = list.intersection(list_2, list_3)
  local int_4 = list.intersection(list_1, list_2, list_3)

  print(vim.inspect(union_1))
  print(vim.inspect(union_2))
  print(vim.inspect(union_3))
  print(vim.inspect(union_4))
  print (" ")
  print(vim.inspect(sub_1))
  print(vim.inspect(sub_2))
  print(vim.inspect(sub_3))
  print(vim.inspect(sub_4))
  print (" ")
  print(vim.inspect(int_1))
  print(vim.inspect(int_2))
  print(vim.inspect(int_3))
  print(vim.inspect(int_4))
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
  -- list_test()
  -- arg_test("jedan", "dva", {"tri", "cetiri"})
  -- nmap_test()
  -- do return end

  reload('alt-modes.test.modes')

  local modes = require("alt-modes.test.modes")
  local M = require("alt-modes")

  M:add('testing', modes.testing)
  M:enter('testing')
end

return run_test
