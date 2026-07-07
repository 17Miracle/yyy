vim.pack.add({
	{ src = "https://codeberg.org/comfysage/artio.nvim" },
	{ src = "https://github.com/nvim-mini/mini.icons" },
})

require("vim._core.ui2").enable({
	enable = true,
	msg = { target = "msg" },
})

local artio = require("artio")
artio.setup({
	opts = {
		marker = "𑪛",
		use_icons = true,
	},
	mappings = {
		["<down>"] = "down",
		["<up>"] = "up",
		["<cr>"] = "accept",
		["<esc>"] = "cancel",
		["<tab>"] = "mark",
		["<c-g>"] = "togglelive",
		["<c-l>"] = "togglepreview",
		["<c-q>"] = "setqflist",
		["<m-q>"] = "setqflistmark",
	},
})

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = artio.select

local map = vim.keymap.set
local opts = { silent = true }

local pickers = {
	["<leader><leader>"] = "(artio-files)",
	["<leader>fg"] = "(artio-grep)",
	["<leader>ff"] = "(artio-smart)",
	["<leader>fb"] = "(artio-buffers)",
	["<leader>f/"] = "(artio-buffergrep)",
	["<leader>fo"] = "(artio-oldfiles)",
}

for lhs, plug in pairs(pickers) do
	map("n", lhs, "<Plug>" .. plug, opts)
end
