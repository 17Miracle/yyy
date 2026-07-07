local blink = require("blink.cmp")

-- Rebuild Blink's native fuzzy matcher
vim.api.nvim_create_user_command("BlinkBuild", function()
	blink.build():pwait()
end, {})

blink.setup({
	fuzzy = { implementation = "rust" },
})
