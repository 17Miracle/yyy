vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("conform").setup({
	formatters_by_ft = {
		go = { "gopls" },
		lua = { "stylua" },
		yaml = { "yamlfmt" },
		python = { "ruff" },
		["_"] = { "trim_newlines", "trim_whitespace" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	format_on_save = {
		timeout_ms = 1000,
	},
})
