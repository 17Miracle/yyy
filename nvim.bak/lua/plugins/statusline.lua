vim.pack.add({
	{ src = 'https://github.com/comfysage/lylla.nvim' },
	{ src = "https://github.com/nvim-mini/mini.icons" },
})

local modes = {
	["n"] = "hello :3",
	["i"] = "type >ᴗ<",
	["v"] = "visual oᴗo",
	["V"] = "visual OᴗO",
	[""] = "visual UᴗU",
	["R"] = "replace -ᴗ-",
	["c"] = "cmd xᴗx",
	["no"] = "no ???",
}

local severities = {
	[1] = { "MiniIconsRed", "" },
	[2] = { "MiniIconsYellow", "" },
	[3] = { "MiniIconsBlue", "" },
	[4] = { "MiniIconsAzure", "" },
}

local lylla = require("lylla")
local utils = require("lylla.utils")
local colors = require("evergarden.colors").get()

lylla.setup({
	refresh_rate = math.huge,
	hls = {
		normal = { fg = colors.green },
		insert = { fg = colors.text },
		visual = { fg = colors.yellow },
		replace = { fg = colors.blue },
		command = { fg = colors.purple },
		operator = { fg = colors.red },
	},
	modules = {
		lylla.component(function()
			local _, hl = utils.get_modehl()
			return {
				{ section = hl },
				" ",
				{ modes[vim.api.nvim_get_mode().mode], { fg = colors.crust } },
				" ",
				{ section = false },
			}
		end, {
			events = { "ModeChanged", "CmdlineEnter" },
		}),
		{ " %l:%c %p%% ", { link = "CursorLine" } },
		lylla.component(function()
			if not package.loaded["vim.diagnostic"] then
				return ""
			end

			local diag = vim.diagnostic.get(0)

			local counts = vim.iter(ipairs(diag)):fold({}, function(v, _, d)
				v[d.severity] = (v[d.severity] or 0) + 1
				return v
			end)

			local formatted = vim
				.iter(pairs(counts))
				:map(function(s, c)
					local sev = severities[s]
					return { string.format(" %s %d", sev[2], c), sev[1] }
				end)
				:totable()

			return formatted
		end, {
			events = { "DiagnosticChanged" },
		}),
		{ "%=" },
		lylla.component(function()
			local icons = require("mini.icons")

			local separator = " | "
			local modified = " "
			local filetype = vim.bo.filetype
			local filename = vim.fn.expand("%:t")
			local icon, icon_hl = icons.get("filetype", filetype)
			local _, file_hl = icons.get("default", "file")

			if #filename == 0 then
				separator = ""
			end

			if vim.bo.modified then
				modified = " [+] "
			elseif not vim.bo.modifiable then
				modified = " [-] "
			end

			return {
				{ modified },
				{ utils.getfilepath()[1], file_hl },
				{ filename, file_hl },
				{ separator },
				{ filetype },
				{ " " },
				{ icon, icon_hl },
				{ " " },
			}
		end, {
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"FileChangedShellPost",
				"Filetype",
			},
		}),
	},
})
