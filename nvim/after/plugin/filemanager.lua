require("vim._core.ui2").enable({
	enable = true,
	msg = { target = "msg" },
})

require("dired").setup({
	show_icons = true,

	keybinds = {
		dired_enter = "<CR>",
		dired_up = "_",
		dired_back = "-",
		dired_rename = "r",
		dired_create = "d",
		dired_delete = "D",

		dired_copy = "y",
		dired_move = "m",
		dired_paste = "p",

		dired_shell_cmd = "!",
		dired_shell_cmd_marked = "&",

		dired_toggle_hidden = ".",
		dired_toggle_sort_order = ",",
		dired_toggle_icons = "i",
		dired_toggle_colors = "c",
		dired_toggle_hide_details = "(",

		dired_mark = "<Tab>",
		dired_copy_marked = "Y",
		dired_move_marked = "M",
		dired_delete_marked = "<Tab>D",

		dired_mark_range = "<Tab>",
		dired_copy_range = "Y",
		dired_move_range = "M",
		dired_delete_range = "<Tab>D",

		dired_quit = "q",
	},
})

local map = vim.keymap.set
map("n", "<leader>pv", "<cmd>Dired<cr>", {
	desc = "Open emacs-style file manager",
})
