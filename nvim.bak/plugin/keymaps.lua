local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- stylua: ignore start
-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Keep search results centered
map("n", "n", "nzzzv", vim.tbl_extend("force", opts, {
  desc = "Next search result",
}))
map("n", "N", "Nzzzv", vim.tbl_extend("force", opts, {
  desc = "Previous search result",
}))

-- Make $ go to last non-blank character instead of absolute EOL
map({ "n", "v", "o" }, "$", "g_", vim.tbl_extend("force", opts, {
  desc = "End of line (non-blank)",
}))

-- Make Ctrl+C behave like Escape in Insert mode
map("i", "<C-c>", "<Esc>", opts)

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", '"+y', vim.tbl_extend("force", opts, {
  desc = "Yank to clipboard",
}))

-- Yank whole line to system clipboard
map("n", "<leader>Y", '"+Yg_', vim.tbl_extend("force", opts, {
  desc = "Yank line to clipboard",
}))

-- Paste from system clipboard
map({ "n", "v" }, "<leader>p", '"+p', vim.tbl_extend("force", opts, {
  desc = "Paste from clipboard",
}))

-- Paste over selection without overwriting unnamed register
map("x", "<leader>P", '"_dP', vim.tbl_extend("force", opts, {
  desc = "Paste without overwriting register",
}))

-- Allow :W, :Q, etc.
vim.cmd([[
  command! W  w
  command! Wq wq
  command! WQ wq
  command! Q  q
]])
