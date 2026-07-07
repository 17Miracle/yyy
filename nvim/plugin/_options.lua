local g = vim.g
local wo = vim.wo
local opt = vim.opt

-- Leader keys
g.mapleader = " "
g.maplocalleader = " "

-- General editor behavior
opt.guicursor = ""
vim.o.shell = os.getenv("SHELL") or "/bin/sh"
vim.o.keywordprg = ":vertical botright help"

opt.updatetime = 100
opt.timeoutlen = 500
opt.ttimeoutlen = 50
opt.redrawtime = 10000
opt.maxmempattern = 20000

opt.hidden = true
opt.confirm = true
opt.autoread = true
opt.autowrite = true
opt.errorbells = false
opt.backspace = "indent,eol,start"
opt.autochdir = false
opt.mouse = ""
opt.encoding = "UTF-8"
opt.modifiable = true

-- Line numbers & scrolling
opt.number = true
opt.relativenumber = true
opt.cursorline = false
opt.numberwidth = 4
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.smoothscroll = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.infercase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "split"

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cmdheight = 0
opt.showmode = true
opt.ruler = false
opt.laststatus = 3
opt.list = false
opt.linebreak = true
opt.winborder = "single"
opt.winminwidth = 5
opt.winblend = 0
opt.fillchars = {
	foldopen = " ",
	foldclose = " ",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
opt.jumpoptions = "stack,view,clean"
opt.shortmess:append("WICcs")

-- Completion & popups
opt.pumheight = 10
opt.pumblend = 10
opt.completeopt = "menuone,noinsert,popup"
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildoptions = "fuzzy,pum,tagfile"
opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })

-- Visual / text rendering
opt.showmatch = false
opt.conceallevel = 2
opt.concealcursor = "c"
opt.synmaxcol = 300
opt.virtualedit = "block"

-- File handling & undo
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
local undodir = vim.fn.expand("~/.local/state/nvim/undo")
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end
opt.undodir = undodir

-- Folding
wo.foldmethod = "expr"
opt.foldlevel = 99

-- External tools
opt.grepprg = vim.fn.executable("rg") == 1 and "rg --vimgrep -. --" or "grep -rni --"
opt.grepformat = "%f:%l:%c:%m"
g.findprg = vim.fn.executable("fd") == 1 and "fd -H -p -t f --color=never --" or "find . -type f -iregex '.*'"

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Diff
opt.diffopt:append("linematch:60")

-- Other behavior
opt.sessionoptions = "help,tabpages,winsize"
opt.iskeyword:append("-")
opt.path:append("**")
opt.selection = "exclusive"

-- Globals & plugins
g.autoformat = true
g.trouble_lualine = true
g.markdown_recommended_style = 0

-- Filetype detection
vim.filetype.add({
	extension = { env = "dotenv" },
	filename = { [".env"] = "dotenv", ["env"] = "dotenv" },
	pattern = {
		["[jt]sconfig.*.json"] = "jsonc",
		["%.env%.[%w_.-]+"] = "dotenv",
	},
})
