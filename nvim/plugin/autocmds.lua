local o = vim.o
local fn = vim.fn
local api = vim.api
local uv = vim.uv

local autocmd = api.nvim_create_autocmd
local create_group = api.nvim_create_augroup

local function augroup(name)
	return create_group("user_" .. name, { clear = true })
end

-- Highlight yanked text
-- autocmd("TextYankPost", {
--   group = augroup("yank_highlight"),
--   callback = function()
--     vim.hl.hl_op(vim.v.event, {
--       type = "highlight",
--       hl_group = "IncSearch",
--       timeout = 150,
--     })
--   end,
-- })

-- Check if files changed outside Neovim
autocmd({ "FocusGained", "ShellCmdPost" }, {
	group = augroup("checktime"),
	callback = function()
		if fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
})

-- Handle files changed outside Neovim
autocmd("FileChangedShellPost", {
	group = augroup("auto_reload"),
	callback = function()
		vim.schedule(function()
			local bufnr = api.nvim_get_current_buf()

			if not api.nvim_buf_is_valid(bufnr) then
				return
			end

			if vim.bo[bufnr].buftype ~= "" then
				return
			end

			local filename = fn.expand("%:t")

			if vim.bo[bufnr].modified then
				vim.notify(
					string.format("%s changed on disk but has unsaved changes. Use :e! to reload.", filename),
					vim.log.levels.WARN,
					{ title = "File Changed" }
				)
				return
			end

			local ok = pcall(function()
				if hard_reload_current_buffer then
					hard_reload_current_buffer()
				else
					vim.cmd("edit")
				end

				if refresh_syntax_and_highlights then
					refresh_syntax_and_highlights(bufnr)
				end

				vim.notify(string.format("Reloaded: %s", filename), vim.log.levels.INFO, { title = "File Changed" })
			end)

			if not ok then
				pcall(vim.cmd, "silent! checktime")
			end
		end)
	end,
})

-- Create missing directories before saving
autocmd("BufWritePre", {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end

		local file = uv.fs_realpath(event.match) or event.match
		fn.mkdir(fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Markdown settings
autocmd("FileType", {
	group = augroup("markdown"),
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
		vim.opt_local.conceallevel = 2
		vim.opt_local.indentexpr = ""
	end,
})

-- Plain text settings
autocmd("FileType", {
	group = augroup("text"),
	pattern = "text",
	callback = function()
		vim.opt_local.conceallevel = 2
	end,
})

-- Close temporary windows with q
autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"qf",
		"help",
		"man",
		"lspinfo",
		"checkhealth",
		"startuptime",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false

		vim.keymap.set("n", "q", "<cmd>close<cr>", {
			buffer = event.buf,
			silent = true,
			desc = "Close window",
		})
	end,
})

-- Keep scrolloff near end of file
autocmd({ "CursorMoved", "CursorMovedI", "WinScrolled" }, {
	group = augroup("scroll_eof"),
	callback = function()
		if api.nvim_win_get_config(0).relative ~= "" then
			return
		end

		local win_height = fn.winheight(0)
		local scrolloff = math.min(o.scrolloff, math.floor(win_height / 2))
		local distance = win_height - fn.winline()

		if distance < scrolloff then
			local view = fn.winsaveview()

			fn.winrestview({
				topline = view.topline + scrolloff - distance,
			})
		end
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("terminal_q_to_close", { clear = true }),
	callback = function(event)
		-- Make 'q' in normal mode close the window
		vim.keymap.set("n", "q", "<cmd>close<cr>", {
			buffer = event.buf,
			silent = true,
			desc = "Close terminal window",
		})

		-- Optional: automatically go to normal mode when the job finishes
		-- (so you don't have to manually press <C-\><C-n>)
		vim.api.nvim_create_autocmd("TermClose", {
			buffer = event.buf,
			once = true,
			callback = function()
				vim.cmd("stopinsert") -- leaves terminal mode
			end,
		})
	end,
})

-- Настройка терминала: размер 40% максимум, затем автосжатие
autocmd("TermOpen", {
	group = augroup("term_auto_resize", { clear = true }),
	callback = function()
		-- Ограничиваем высоту 40% от всего окна Neovim
		local max_height = math.floor(vim.o.lines * 0.25)
		vim.cmd("resize " .. max_height)
	end,
})
