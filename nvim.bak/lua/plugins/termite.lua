vim.pack.add({
	{ src = "https://github.com/ruicsh/termite.nvim" },
})

local termite = require("termite")
termite.setup({
	width = 0.5, -- Fraction of editor width for left/right positions (0.0 - 1.0)
	height = 0.5, -- Fraction of editor height for top/bottom positions (0.0 - 1.0)
	position = "bottom", -- Panel position: "left", "right", "top", or "bottom"
	border = "light", -- Border style: "light", "heavy", "double", "double-dash", "triple-dash", "quadruple-dash"
	shell = nil, -- Shell command (nil = default $SHELL)
	start_insert = true, -- Enter insert mode when focusing a terminal
	click_to_insert = true, -- Enter insert mode when clicking a terminal window
	winbar = true, -- Show winbar with running process or cwd

	keymaps = {
		toggle = "<C-\\>", -- Toggle all terminals (terminal mode)
		create = "<C-t>", -- Create new terminal
		next = "<C-n>", -- Focus next terminal in stack
		prev = "<C-p>", -- Focus previous terminal in stack
		focus_editor = "<C-e>", -- Return focus to editor window
		normal_mode = "<C-[>", -- Exit terminal insert mode
		maximize = "<C-z>", -- Maximize/restore focused terminal
		close = "q", -- Close current terminal (normal mode)
	},

	wo = { -- Window options applied to terminal windows
		signcolumn = "yes:1",
	},

	highlights = {
		border_active = "TermiteBorder", -- Highlight for active terminal border (string = hl group, table = direct definition)
		border_inactive = "TermiteBorderNC", -- Highlight for inactive terminal borders (string = hl group, table = direct definition)
		border_single = "TermiteBorderSingle", -- Highlight for single terminal border (string = hl group, table = direct definition)
		winbar = "TermiteWinbar", -- Highlight for winbar
	},
})
