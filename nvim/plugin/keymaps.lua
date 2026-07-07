local map = vim.keymap.set

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Keep search results centered
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })

-- Make $ go to last non-blank character instead of absolute EOL
map({ "n", "v", "o" }, "$", "g_")

-- Make Ctrl+C behave like Escape in Insert mode
map("i", "<C-c>", "<Esc>")

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", '"+y')

-- Yank whole line to system clipboard
map("n", "<leader>Y", '"+yy')

-- Paste from system clipboard
map({ "n", "v" }, "<leader>p", '"+p')

-- Paste over selection without overwriting unnamed register
map("x", "<leader>P", '"_dP')

-- Allow :W, :Q, etc.
vim.cmd([[
  command! W  w
  command! Wq wq
  command! WQ wq
  command! Q  q
]])
