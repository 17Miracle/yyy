vim.pack.add({
	"https://github.com/nvim-mini/mini.surround",
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
