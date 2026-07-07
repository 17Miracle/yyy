vim.pack.add({
	{ src = "https://github.com/nvim-mini/mini.icons" },
})

local icons = require("mini.icons")

icons.setup({
	style = vim.env.TERM ~= "linux" and "glyph" or "ascii",
	file = { [".envrc"] = { glyph = "", hl = "MiniIconsYellow" } },
	lsp = {
		color = { glyph = "󰏘" },
		constant = { glyph = "󰏿" },
		constructor = { glyph = "󰒓" },
		event = { glyph = "󱐋" },
		file = { glyph = "󰈚" },
		["function"] = { glyph = "󰊕" },
		property = { glyph = "󰖷" },
		snippet = { glyph = "󱄽" },
		string = { glyph = "“" },
		value = { glyph = "󰦨" },
		variable = { glyph = "󰆦" },
	},
})
icons.mock_nvim_web_devicons()
