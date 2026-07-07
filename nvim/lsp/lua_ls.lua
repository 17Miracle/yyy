return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".emmyrc.json",
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylua.toml",
		"stylua.toml",
		"selene.toml",
		"selene.yml",
		".git",
	},
	settings = {
		Lua = {
			codeLens = { enable = false },
			completion = { callSnippet = "Replace", displayContext = 1 },
			hint = { enable = true, arrayIndex = "Enable" },
			runtime = { version = "LuaJIT" },
			telemetry = { enabled = false },
			workspace = { library = vim.api.nvim_get_runtime_file("", true) },
		},
	},
}
