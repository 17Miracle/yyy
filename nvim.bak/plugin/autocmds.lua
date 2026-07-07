local o = vim.o
local fn = vim.fn
local opt = vim.opt
local api = vim.api

local autocmd = api.nvim_create_autocmd
local create_group = api.nvim_create_augroup

-- Helper to create isolated augroups
local function augroup(name)
	return create_group("user_" .. name, { clear = true })
end

-- [[ Preserve cursor position after yank ]]
local cursor_pre_yank

vim.keymap.set({ "n", "x" }, "y", function()
	cursor_pre_yank = api.nvim_win_get_cursor(0)
	return "y"
end, { expr = true })

vim.keymap.set("n", "Y", function()
	cursor_pre_yank = api.nvim_win_get_cursor(0)
	return "yg_" -- yank to last non-blank character
end, { expr = true })

-- [[ Restore cursor position after yank ]]
autocmd("TextYankPost", {
	group = augroup("yank_restore_cursor"),
	callback = function()
		if vim.v.event.operator == "y" and cursor_pre_yank then
			api.nvim_win_set_cursor(0, cursor_pre_yank)
		end
	end,
})

-- [[ Highlight yanked text ]]
autocmd("TextYankPost", {
	group = augroup("yank_highlight"),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Resize splits if window got resized
autocmd("VimResized", {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Make it easier to close man-files when opened inline
autocmd("FileType", {
	group = augroup("man_unlisted"),
	pattern = "man",
	callback = function(event)
		vim.bo[event.buf].buflisted = false
	end,
})

-- Close some filetypes with <q>
autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false

		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(api.nvim_buf_delete, event.buf, { force = true })
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer",
			})
		end)
	end,
})

-- Fix conceallevel for json files
autocmd("FileType", {
	group = augroup("json_conceal"),
	pattern = { "json", "jsonc", "json5" },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

-- Treat *.env and .env.* files as shell scripts
autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup("env_filetype"),
	pattern = { "*.env", ".env.*" },
	callback = function()
		vim.opt_local.filetype = "sh"
	end,
})

-- Force *.tomg-config* files to use TOML filetype
autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup("toml_filetype"),
	pattern = { "*.tomg-config*" },
	callback = function()
		vim.opt_local.filetype = "toml"
	end,
})

-- VSCode-style snippet files should be treated as JSON
autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup("code_snippets_filetype"),
	pattern = "*.code-snippets",
	callback = function()
		vim.opt_local.filetype = "json"
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd("BufWritePre", {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end

		local file = vim.uv.fs_realpath(event.match) or event.match
		fn.mkdir(fn.fnamemodify(file, ":p:h"), "p")
	end,
})
