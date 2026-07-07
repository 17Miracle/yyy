vim.pack.add({
	{ src = "https://github.com/juniorsundar/refer.nvim" },
	{ src = "https://github.com/nvim-mini/mini.icons" },
})

require("vim._core.ui2").enable({
	enable = true,
	msg = { target = "msg" },
})

local refer = require("refer")
refer.setup({
	extras = {
		find_file = true, -- set to true to register :Refer Extras FindFile
	},
})

refer.setup_ui_select()
