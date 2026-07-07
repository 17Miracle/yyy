require("arborist").setup({
	update_cadence = "weekly",
	install_popular = false,
	ensure_installed = {
		"awk",
		"bash",
		"css",
		"dockerfile",
		"go",
		"gomod",
		"hcl",
		"helm",
		"ini",
		"json",
		"jsonnet",
		"lua",
		"markdown",
		"markdown_inline",
		"nginx",
		"promql",
		"python",
		"regex",
		"terraform",
		"toml",
		"yaml",
	},

	disable = {
		indent = {
			"markdown",
		},
	},
})
