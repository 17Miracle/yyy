vim.pack.add({
  { src = "https://github.com/zaldih/themery.nvim" },
  { src = "https://github.com/oskarnurm/koda.nvim" },
  { src = "https://github.com/GasimGasimzada/intent.nvim" },
  { src = "https://github.com/blazkowolf/gruber-darker.nvim" },
  { src = "https://github.com/WTFox/jellybeans.nvim" },
  { src = "https://github.com/metalelf0/kintsugi-nvim" },
  { src = "https://github.com/zitrocode/carvion.nvim", name = 'carvion' },
  { src = "https://github.com/marekh19/meowsoot.nvim" },
  { src = "https://github.com/sainnhe/gruvbox-material" },
  { src = "https://codeberg.org/evergarden/nvim.git", name = "evergarden" },
})

require("evergarden").setup({
	theme = {
		variant = "fall",
		accent = "green",
	},
	style = {
		tabline = { "reverse" },
		search = { "reverse" },
		incsearch = { "reverse" },
		types = {},
		keyword = {},
		comment = {},
	},
	cache = false,
	default_integrations = true,
	integraions = {
		blink_cmp = true,
		gitsigns = true,
		mini = {
			enable = true,
			hipatterns = true,
			icons = true,
			surround = true,
		},
	},
	overrides = {},
})

-- Minimal config
require("themery").setup({
	themes = { "gruvbox-material", "evergarden", "koda", "meowsoot", "kintsugi-flared", "carvion", "intent", "gruber-darker", "jellybeans-default" },
	livePreview = true,
})

local map = vim.keymap.set
local opts = { silent = true }

map("n", "<leader>tt", function()
  local themery = require("themery")
  local current = themery.getCurrentTheme()
  local current_name = current and current.name or ""

  -- Список ваших тем в порядке переключения
  local themes = { "gruvbox-material", "koda", "evergarden", "meowsoot", "kintsugi-flared", "carvion", "intent", "gruber-darker", "jellybeans-default" }
  local next_theme = themes[1]

  -- Поиск текущей темы и выбор следующей
  for i, name in ipairs(themes) do
    if current_name == name then
      next_theme = themes[i + 1] or themes[1]
      break
    end
  end

  themery.setThemeByName(next_theme, true)
end, opts)
