vim.pack.add({
	{ src = "https://github.com/GooseRooster/cairn.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

require("vim._core.ui2").enable({
	enable = true,
	msg = { target = "msg" },
})

local cairn = require("cairn")
cairn.setup()
