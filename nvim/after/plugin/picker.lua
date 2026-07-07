require("refer").setup({
	max_height_percent = 0.3,
	debounce_ms = 40,
	min_query_len = 1,
	preview = {
		enabled = false,
		max_lines = 500,
	},
	ui = {
		mark_char = "●",
		mark_hl = "DiagnosticInfo",

		input_position = "bottom",

		reverse_result = true,

		winhighlight = table.concat({
			"Normal:Normal",
			"FloatBorder:Normal",
			"WinSeparator:Normal",
			"StatusLine:Normal",
			"StatusLineNC:Normal",
		}, ","),

		highlights = {
			prompt = "Title",
			selection = "Visual",
			header = "Comment",
		},
	},
	providers = {
		files = {
			ignored_dirs = {
				".git",
				".jj",
				".cache",

				"node_modules",
				".venv",
				"venv",

				".terraform",
				".direnv",

				"dist",
				"build",

				"__pycache__",

				".pytest_cache",
				".mypy_cache",
			},
			find_command = {
				"fd",
				"-H",
				"--follow",
				"--type",
				"f",
				"--color",
				"never",
			},
		},

		grep = {
			grep_command = { "rg", "--vimgrep", "--smart-case", "--hidden" },
		},
	},

	extras = { find_file = true },
})

require("refer").setup_ui_select()

local map = vim.keymap.set

map("n", "<leader><leader>", "<cmd>Refer Files<cr>", {
	desc = "Fuzzy find files using fd (Async)",
})

map("n", "<leader>/", "<cmd>Refer Grep<cr>", {
	desc = "Live grep using ripgrep (Async)",
})

map("n", "<leader>f", "<cmd>Refer Extras FindFile<cr>", {
	desc = "Emacs-style filesystem picker",
})

map("n", "<leader>o", "<cmd>Refer OldFiles<cr>", {
	desc = "Browse recently opened files",
})
