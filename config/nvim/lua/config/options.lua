local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & Indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Line wrapping
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance & UI
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.pumheight = 10
opt.showmode = false

-- Splits behavior
opt.splitright = true
opt.splitbelow = true

-- Clipboard (Wayland / X11 system clipboard integration)
opt.clipboard = "unnamedplus"

-- Undo & Backup
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- Responsiveness & Timings
opt.updatetime = 200
opt.timeoutlen = 300

-- Completion menu options
opt.completeopt = { "menu", "menuone", "noselect" }

-- Mouse support
opt.mouse = "a"

-- Confirm before exiting unsaved buffer
opt.confirm = true
