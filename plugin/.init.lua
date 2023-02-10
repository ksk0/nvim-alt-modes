vim.cmd [[
  nnoremap <silent> <C-k> :lua require("alt-modes.test")()<CR>
  nnoremap <silent> <leader>K :lua require("alt-modes.core.reload")()<CR>
]]

vim.notify("Loaded init script")
