local g = vim.g
local wo = vim.wo
local opt = vim.opt

-- Leader keys
g.mapleader = " " -- Main leader key
g.maplocalleader = " " -- Local leader key

-- Editor
opt.guicursor = "" -- Use block cursor in all modes
vim.o.shell = os.getenv("SHELL") or "/bin/sh" -- Use current shell, fallback to sh
vim.o.keywordprg = ":vertical botright help" -- Open :help in a vertical split

-- Line numbers & scrolling
opt.number = true -- Show absolute line numbers
opt.relativenumber = false -- No relative line numbers
opt.cursorline = false -- Don't highlight current line
opt.cursorlineopt = "both" -- Highlight both the line and the line number
opt.numberwidth = 4 -- Fixed width for number column (prevents layout shifts)
opt.wrap = false -- Don't wrap long lines
opt.scrolloff = 8 -- Keep 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8 -- Keep 8 columns left/right when scrolling horizontally

-- Indentation
opt.tabstop = 4 -- Tab width
opt.shiftwidth = 4 -- Indent width for >> and <<
opt.softtabstop = 4 -- Spaces inserted when pressing Tab
opt.expandtab = true -- Use spaces instead of tabs
opt.smartindent = true -- Auto-indent new lines based on syntax
opt.autoindent = true -- Copy indent from current line on Enter

-- Search
opt.ignorecase = true -- Case insensitive search by default
opt.smartcase = true -- Case sensitive if query contains uppercase
opt.hlsearch = true -- Highlight all search matches
opt.incsearch = true -- Show matches as you type
opt.inccommand = "split" -- Preview :s substitutions in a split window

-- Visual
opt.termguicolors = true -- Enable 24-bit RGB colors
opt.signcolumn = "yes" -- Always show sign column (prevents layout shifts)
opt.showmatch = false -- Don't jump to matching bracket
opt.matchtime = 2 -- How long to show matching bracket (tenths of a second)
opt.cmdheight = 0 -- Hide command line when not in use
opt.showmode = true -- Show current mode (INSERT, VISUAL, etc.)
opt.pumheight = 10 -- Max number of items in completion popup
opt.pumblend = 10 -- Completion popup transparency (0-100)
opt.winblend = 0 -- Floating window transparency (0 = opaque)
opt.completeopt = "menu,menuone,noselect" -- Completion behavior
opt.conceallevel = 2 -- Hide markup symbols (e.g. * in markdown)
opt.confirm = true -- Ask to save changes instead of failing
opt.concealcursor = "c" -- Only conceal markup in command mode, show it in normal/insert
opt.synmaxcol = 300 -- Don't syntax highlight lines longer than 300 chars (performance)
opt.ruler = false -- Don't show cursor position in statusline (handled by statusline plugin)
opt.virtualedit = "block" -- Allow cursor to move past end of line in visual block mode
opt.winborder = "single" -- Border style for floating windows: "single" | "double" | "rounded" | "shadow" | "none"
opt.winminwidth = 5 -- Minimum width of any window

-- File handling
opt.backup = false -- Don't create backup files
opt.writebackup = false -- Don't create backup before overwriting a file
opt.swapfile = false -- Don't create swap files
opt.undofile = true -- Persist undo history across sessions
opt.undolevels = 10000 -- Maximum number of undo steps
opt.undodir = vim.fn.expand("~/.local/state/nvim/undo") -- Where to store undo files
opt.updatetime = 50 -- Delay before writing swap file and triggering CursorHold (ms)
opt.timeoutlen = 500 -- Time to wait for a key sequence to complete (ms)
opt.ttimeoutlen = 0 -- Time to wait for a terminal key code (ms)
opt.autoread = true -- Auto reload file if changed outside Neovim
opt.autowrite = true -- Auto save before :make, :next, etc.

-- Behavior
opt.hidden = true -- Allow switching buffers without saving
opt.errorbells = false -- No beep on errors
opt.backspace = "indent,eol,start" -- Allow backspace over indents, line breaks, insert start
opt.autochdir = false -- Don't auto-change working directory
opt.iskeyword:append("-") -- Treat dash-separated words as one word (e.g. my-var)
opt.path:append("**") -- Search recursively in subdirectories with :find
opt.selection = "exclusive" -- Visual selection excludes the character under cursor
opt.mouse = "" -- Disable mouse support
opt.clipboard = vim.env.SSH_TTY and "" -- Don't sync with system clipboard (use "+y explicitly)
opt.modifiable = true -- Allow editing buffers
opt.encoding = "UTF-8" -- File encoding

-- Folding
opt.smoothscroll = true -- Smooth scrolling when wrapping is on
wo.foldmethod = "expr" -- Use expression for folding (e.g. treesitter)
opt.foldlevel = 99 -- Open all folds by default
opt.formatoptions = "jcroqlnt" -- j: remove comment leader on join, c: auto-wrap comments,
-- r: insert comment leader on Enter, o: on 'o'/'O',
-- q: allow formatting with gq, l: don't break long lines,
-- n: recognize numbered lists, t: auto-wrap text
opt.grepformat = "%f:%l:%c:%m" -- Format for grep output: file:line:col:message
opt.grepprg = vim.fn.executable("rg") == 1 and "rg --vimgrep -. --" or "grep -rni --"
-- Use ripgrep if available (faster, includes hidden files), fallback to grep

-- Splits
opt.splitbelow = true -- Horizontal splits open below current window
opt.splitright = true -- Vertical splits open to the right
opt.splitkeep = "screen" -- Keep text on screen when splitting

-- Command-line completion
opt.wildmenu = true -- Show completion menu in command line
opt.wildmode = "longest:full,full" -- Complete longest common match first, then cycle
opt.wildoptions = "fuzzy,pum,tagfile" -- Fuzzy matching + popup menu in command line
opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" }) -- Ignore compiled files

-- Diff
opt.diffopt:append("linematch:60") -- Better diff alignment for blocks up to 60 lines

-- Performance
opt.redrawtime = 10000 -- Max time (ms) spent on syntax highlighting per redraw
opt.maxmempattern = 20000 -- Max memory (KB) for regex pattern matching

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.local/state/nvim/undo")
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end

-- Globals
g.autoformat = true -- Enable autoformatting on save (used by formatter plugins)
g.trouble_lualine = true -- Show Trouble diagnostics count in lualine

-- UI characters
opt.fillchars = {
	foldopen = " ", -- Icon for open fold
	foldclose = " ", -- Icon for closed fold
	fold = " ", -- Fill character for fold lines
	foldsep = " ", -- Separator between folds
	diff = "╱", -- Fill character for deleted lines in diff
	eob = " ", -- Hide ~ at end of buffer
}

opt.jumpoptions = "view" -- Restore window view when jumping back in jumplist
opt.laststatus = 3 -- Single global statusline for all windows
opt.list = false -- Don't show invisible characters (listchars)
opt.linebreak = true -- Wrap at word boundaries, not mid-word
opt.shiftround = true -- Round indents to multiples of shiftwidth
opt.shiftwidth = 4 -- Size of one indent level
opt.shortmess:append({ W = true, I = true, c = true, C = true })
-- W: don't show [w] when writing, I: skip intro screen,
-- c: no ins-completion messages, C: no scanning messages

g.markdown_recommended_style = 0 -- Disable Neovim's default markdown indent/style overrides

Filetype detection
vim.filetype.add({
	extension = {
		env = "dotenv",
	},
	filename = {
		[".env"] = "dotenv",
		["env"] = "dotenv",
	},
	pattern = {
		["[jt]sconfig.*.json"] = "jsonc",
		["%.env%.[%w_.-]+"] = "dotenv",
	},
})
