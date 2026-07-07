require("mini.ai").setup()
require("mini.move").setup()

require("mini.hipatterns").setup({
	highlighters = { hex_color = require("mini.hipatterns").gen_highlighter.hex_color() },
})

require("mini.surround").setup({
	mappings = {
		add = "sa",
		delete = "sd",
		find = "",
		find_left = "",
		highlight = "",
		replace = "sr",
		update_n_lines = "",

		suffix_last = "",
		suffix_next = "",
	},

	search_method = "cover_or_next",
})

require("mini.icons").setup({
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
require("mini.icons").mock_nvim_web_devicons()
