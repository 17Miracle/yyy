require("meowsoot").setup({
	styles = { comments = {}, functions = { bold = true } },
	plugins = { blink = true, mini_icons = true, trouble = true },
	on_highlights = function(hl)
		for _, g in pairs(hl) do
			if type(g) == "table" then
				g.italic = false
			end
		end
	end,
})

require("koda").setup({
	styles = { functions = { bold = true } },
})

local themes = { "meowsoot", "koda" }
local sf = vim.fn.stdpath("state") .. "/theme"
local ok, lines = pcall(vim.fn.readfile, sf)
local idx = ok and tonumber(lines[1]) or 1

vim.cmd.colorscheme(themes[idx])
vim.keymap.set("n", "<leader>tt", function()
	idx = idx % #themes + 1
	vim.cmd.colorscheme(themes[idx])
	vim.fn.writefile({ tostring(idx) }, sf)
end)
