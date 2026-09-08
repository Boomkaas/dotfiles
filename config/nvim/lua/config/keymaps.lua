local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key definition
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-------------------------------------------------------------------------------
-- 1. UNIVERSAL IDE HOTKEYS (VS Code / JetBrains / Zed / Cursor)
-------------------------------------------------------------------------------

-- File & Command Palette Operations
map({ "n", "i", "v" }, "<C-p>", "<cmd>Telescope find_files<CR>", { desc = "Quick Open File (IDE: Ctrl+P)" })
map({ "n", "i", "v" }, "<C-S-p>", "<cmd>Telescope commands<CR>", { desc = "Command Palette (IDE: Ctrl+Shift+P)" })
map({ "n", "i", "v" }, "<F1>", "<cmd>Telescope commands<CR>", { desc = "Command Palette (IDE: F1)" })

-- Search & Replace
map({ "n", "i", "v" }, "<C-S-f>", "<cmd>Telescope live_grep<CR>", { desc = "Find in Files / Global Search (IDE: Ctrl+Shift+F)" })
map({ "n", "i", "v" }, "<C-f>", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Find in Buffer (IDE: Ctrl+F)" })
map({ "n", "i", "v" }, "<C-S-h>", "<cmd>GrugFar<CR>", { desc = "Find & Replace in Files (IDE: Ctrl+Shift+H)" })

-- Hotkeys Cheatsheet & Explorer
map({ "n", "i", "v" }, "<C-h>", function() require("config.cheatsheet").toggle() end, { desc = "Toggle IDE Hotkeys Cheatsheet (Ctrl+H)" })
map("n", "<leader>?", function() require("config.cheatsheet").toggle() end, { desc = "Toggle IDE Hotkeys Cheatsheet" })

-- Sidebar / File Explorer
map({ "n", "i", "v" }, "<C-b>", "<cmd>Neotree toggle<CR>", { desc = "Toggle Sidebar / Explorer (IDE: Ctrl+B)" })
map({ "n", "i", "v" }, "<C-\\>", "<cmd>Neotree toggle<CR>", { desc = "Toggle Sidebar (IDE: Ctrl+\\)" })
map({ "n", "i", "v" }, "<C-S-e>", "<cmd>Neotree focus<CR>", { desc = "Focus File Explorer (IDE: Ctrl+Shift+E)" })

-- Integrated Terminal & Problems Panel
map({ "n", "t", "i" }, "<C-`>", "<cmd>ToggleTerm direction=float<CR>", { desc = "Toggle Integrated Terminal (IDE: Ctrl+`)" })
map({ "n", "t", "i" }, "<C-~>", "<cmd>ToggleTerm direction=float<CR>", { desc = "Toggle Integrated Terminal (IDE: Ctrl+~)" })
map({ "n", "i", "v" }, "<C-S-m>", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Toggle Problems / Diagnostics (IDE: Ctrl+Shift+M)" })

-- Symbols & Outline
map({ "n", "i", "v" }, "<C-S-o>", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Go to Symbol in File (IDE: Ctrl+Shift+O)" })
map({ "n", "i", "v" }, "<C-t>", "<cmd>Telescope lsp_workspace_symbols<CR>", { desc = "Go to Symbol in Workspace (IDE: Ctrl+T)" })

-- File Save, Close, & New
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save File (IDE: Ctrl+S)" })
map({ "n", "i", "v" }, "<C-w>", "<cmd>bdelete<CR>", { desc = "Close Editor Tab (IDE: Ctrl+W)" })
map({ "n", "i", "v" }, "<C-S-n>", "<cmd>enew<CR>", { desc = "New File (IDE: Ctrl+Shift+N)" })

-- Select All
map({ "n", "i", "v" }, "<C-a>", "<Esc>ggVG", { desc = "Select All (IDE: Ctrl+A)" })

-- Clipboard Operations (Cut / Copy / Paste with system clipboard)
map("v", "<C-c>", '"+y', { desc = "Copy Selection (IDE: Ctrl+C)" })
map("v", "<C-x>", '"+x', { desc = "Cut Selection (IDE: Ctrl+X)" })
map("v", "<C-v>", '"+p', { desc = "Paste (IDE: Ctrl+V)" })
map("n", "<C-v>", '"+p', { desc = "Paste (IDE: Ctrl+V)" })
map("i", "<C-v>", '<C-r>+', { desc = "Paste (IDE: Ctrl+V)" })

-- Undo & Redo
map("i", "<C-z>", "<C-o>u", { desc = "Undo (IDE: Ctrl+Z)" })
map("n", "<C-z>", "u", { desc = "Undo (IDE: Ctrl+Z)" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Redo (IDE: Ctrl+Y)" })
map("n", "<C-y>", "<C-r>", { desc = "Redo (IDE: Ctrl+Y)" })
map({ "n", "i" }, "<C-S-z>", "<C-r>", { desc = "Redo (IDE: Ctrl+Shift+Z)" })

-- Line Commenting (Ctrl+/ and Ctrl+_)
map("n", "<C-/>", "<cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>", { desc = "Toggle Line Comment (IDE: Ctrl+/)" })
map("n", "<C-_>", "<cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>", { desc = "Toggle Line Comment (IDE: Ctrl+_)" })
map("v", "<C-/>", ":<C-u>lua require('mini.comment').toggle_lines(vim.fn.line(\"'<\"), vim.fn.line(\"'>\"))<CR>gv", { desc = "Toggle Comment (IDE: Ctrl+/)" })
map("v", "<C-_>", ":<C-u>lua require('mini.comment').toggle_lines(vim.fn.line(\"'<\"), vim.fn.line(\"'>\"))<CR>gv", { desc = "Toggle Comment (IDE: Ctrl+_)" })
map("i", "<C-/>", "<Esc><cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>a", { desc = "Toggle Line Comment (IDE: Ctrl+/)" })
map("i", "<C-_>", "<Esc><cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>a", { desc = "Toggle Line Comment (IDE: Ctrl+_)" })

-- Move Line / Selection Up & Down (Alt+Up / Alt+Down or Alt+j / Alt+k)
map("n", "<M-Down>", "<cmd>m .+1<CR>==", { desc = "Move Line Down (IDE: Alt+Down)" })
map("n", "<M-Up>", "<cmd>m .-2<CR>==", { desc = "Move Line Up (IDE: Alt+Up)" })
map("i", "<M-Down>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move Line Down (IDE: Alt+Down)" })
map("i", "<M-Up>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move Line Up (IDE: Alt+Up)" })
map("v", "<M-Down>", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down (IDE: Alt+Down)" })
map("v", "<M-Up>", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up (IDE: Alt+Up)" })

map("n", "<M-j>", "<cmd>m .+1<CR>==", { desc = "Move Line Down (IDE: Alt+J)" })
map("n", "<M-k>", "<cmd>m .-2<CR>==", { desc = "Move Line Up (IDE: Alt+K)" })
map("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down (IDE: Alt+J)" })
map("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up (IDE: Alt+K)" })

-- Duplicate Line / Selection Up & Down (Shift+Alt+Down / Shift+Alt+Up)
map("n", "<M-S-Down>", "<cmd>t.<CR>", { desc = "Duplicate Line Down (IDE: Shift+Alt+Down)" })
map("n", "<M-S-Up>", "<cmd>t.-1<CR>", { desc = "Duplicate Line Up (IDE: Shift+Alt+Up)" })
map("i", "<M-S-Down>", "<Esc><cmd>t.<CR>gi", { desc = "Duplicate Line Down (IDE: Shift+Alt+Down)" })
map("i", "<M-S-Up>", "<Esc><cmd>t.-1<CR>gi", { desc = "Duplicate Line Up (IDE: Shift+Alt+Up)" })
map("v", "<M-S-Down>", ":'<,'>y<CR>'>pgv", { desc = "Duplicate Selection Down (IDE: Shift+Alt+Down)" })
map("v", "<M-S-Up>", ":'<,'>y<CR>'<Pgv", { desc = "Duplicate Selection Up (IDE: Shift+Alt+Up)" })

-- Fast Word Deletion
map("i", "<C-BS>", "<C-w>", { desc = "Delete Word Backward (IDE: Ctrl+Backspace)" })

-------------------------------------------------------------------------------
-- 2. LSP & REFACTORING HOTKEYS (F12, F2, Alt+Enter, etc.)
-------------------------------------------------------------------------------

map({ "n", "i" }, "<F12>", vim.lsp.buf.definition, { desc = "Go to Definition (IDE: F12)" })
map({ "n", "i" }, "<S-F12>", "<cmd>Telescope lsp_references<CR>", { desc = "Find All References (IDE: Shift+F12)" })
map({ "n", "i" }, "<M-F12>", "<cmd>Telescope lsp_references<CR>", { desc = "Find All References (IDE: Alt+F12)" })
map({ "n", "i" }, "<C-F12>", vim.lsp.buf.implementation, { desc = "Go to Implementation (IDE: Ctrl+F12)" })
map({ "n", "i" }, "<F2>", vim.lsp.buf.rename, { desc = "Rename Symbol (IDE: F2)" })
map({ "n", "i", "v" }, "<M-CR>", vim.lsp.buf.code_action, { desc = "Quick Fix / Code Action (IDE: Alt+Enter)" })
map({ "n", "i", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Quick Fix / Code Action (IDE: Ctrl+.)" })
map({ "n", "i", "v" }, "<M-S-f>", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "Format Document (IDE: Shift+Alt+F)" })
map({ "n", "i", "v" }, "<C-S-i>", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "Format Document (IDE: Ctrl+Shift+I)" })
map({ "n", "i" }, "<F8>", vim.diagnostic.goto_next, { desc = "Next Problem (IDE: F8)" })
map({ "n", "i" }, "<S-F8>", vim.diagnostic.goto_prev, { desc = "Previous Problem (IDE: Shift+F8)" })
map({ "n", "i" }, "<C-k>", vim.lsp.buf.hover, { desc = "Hover Documentation (IDE: Ctrl+K)" })
map({ "n", "i" }, "<C-S-Space>", vim.lsp.buf.signature_help, { desc = "Parameter Hints (IDE: Ctrl+Shift+Space)" })

-------------------------------------------------------------------------------
-- 3. TABS & BUFFER NAVIGATION (Ctrl+Tab, Alt+1..9)
-------------------------------------------------------------------------------

map({ "n", "i" }, "<C-Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab (IDE: Ctrl+Tab)" })
map({ "n", "i" }, "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Tab (IDE: Ctrl+Shift+Tab)" })
map({ "n", "i" }, "<C-PageDown>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab (IDE: Ctrl+PageDown)" })
map({ "n", "i" }, "<C-PageUp>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Tab (IDE: Ctrl+PageUp)" })

-- Alt+1..9 to jump directly to tab 1..9
for i = 1, 9 do
  map({ "n", "i" }, "<M-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "Go to Tab " .. i })
end

-------------------------------------------------------------------------------
-- 4. VIM-NATIVE ERGONOMIC SHORTCUTS (<Space> Leader)
-------------------------------------------------------------------------------

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Force quit all" })

-- Window splits
map("n", "<leader>sv", "<C-w>v", { desc = "Split Window Vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split Window Horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make Splits Equal Size" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close Current Split" })

-- Buffer management
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous Buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete Buffer" })
map("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close Buffer" })

-- Stay in visual mode while indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Paste without replacing register content
map("x", "p", [["_dP]], opts)

-- Terminal escape
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
