require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		["_"] = { "trim_newlines", "trim_whitespace" },
	},
	format_on_save = {
		timeout_ms = 1000,
	},
})
