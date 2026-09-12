local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key definition
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-------------------------------------------------------------------------------
-- HELPER FUNCTIONS FOR VS CODE EDITING BEHAVIOR
-------------------------------------------------------------------------------

--- Smart Backspace in Normal Mode
--- Deletes character before cursor; if at col 0, joins with previous line like VS Code
local function smart_backspace_normal()
  local count = vim.v.count1
  for _ = 1, count do
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col > 0 then
      vim.cmd('normal! "_X')
    elseif line > 1 then
      local prev_line = vim.api.nvim_buf_get_lines(0, line - 2, line - 1, false)[1]
      local cur_line = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
      local new_col = #prev_line
      vim.api.nvim_buf_set_lines(0, line - 2, line, false, { prev_line .. cur_line })
      vim.api.nvim_win_set_cursor(0, { line - 1, new_col })
    else
      break
    end
  end
end

--- Smart Delete in Normal Mode
--- Deletes character under cursor; if at end of line or empty line, joins next line
local function smart_delete_normal()
  local count = vim.v.count1
  for _ = 1, count do
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local cur_line = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
    local total_lines = vim.api.nvim_buf_line_count(0)
    if #cur_line == 0 and line < total_lines then
      local next_line = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
      vim.api.nvim_buf_set_lines(0, line - 1, line + 1, false, { next_line })
      vim.api.nvim_win_set_cursor(0, { line, 0 })
    elseif col < #cur_line then
      vim.cmd('normal! "_x')
    elseif line < total_lines then
      local next_line = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
      vim.api.nvim_buf_set_lines(0, line - 1, line + 1, false, { cur_line .. next_line })
      vim.api.nvim_win_set_cursor(0, { line, col })
    else
      break
    end
  end
end

--- Smart Home (Toggle first non-blank character vs column 0)
local function smart_home()
  local col = vim.fn.col(".")
  local first_nonblank = vim.fn.indent(".") + 1
  if col ~= first_nonblank then
    vim.cmd("normal! ^")
  else
    vim.cmd("normal! 0")
  end
end

--- Find and Replace in current file (VS Code: Ctrl+H)
local function replace_current_file()
  local ok, grug = pcall(require, "grug-far")
  if ok then
    local file = vim.fn.expand("%")
    if file ~= "" then
      grug.open({ prefills = { paths = file } })
    else
      grug.open()
    end
  else
    local search = vim.fn.input("Search: ")
    if search and search ~= "" then
      local replace = vim.fn.input("Replace with: ")
      if replace then
        vim.cmd(string.format("%%s/%s/%s/gc", vim.fn.escape(search, "/"), vim.fn.escape(replace, "/")))
      end
    end
  end
end

-------------------------------------------------------------------------------
-- 1. UNIVERSAL VS CODE CORE EDITING & BACKSPACE / DELETE
-------------------------------------------------------------------------------

-- Backspace: Deletes previous symbol in ALL modes (Normal, Visual, Select, Insert)
map("n", "<BS>", smart_backspace_normal, { desc = "Backspace (IDE: Delete left)" })
map("n", "<C-h>", smart_backspace_normal, { desc = "Backspace (IDE: Delete left)" })
map({ "v", "x", "s" }, "<BS>", '"_d', { desc = "Delete Selection (IDE: Backspace)" })
map({ "v", "x", "s" }, "<C-h>", '"_d', { desc = "Delete Selection (IDE: Backspace)" })
map("i", "<BS>", "<BS>", { desc = "Backspace" })
map("i", "<C-h>", "<BS>", { desc = "Backspace" })

-- Delete: Deletes next symbol in ALL modes
map("n", "<Del>", smart_delete_normal, { desc = "Delete (IDE: Delete right)" })
map({ "v", "x", "s" }, "<Del>", '"_d', { desc = "Delete Selection (IDE: Delete)" })
map("i", "<Del>", "<Del>", { desc = "Delete Forward" })

-- Word Deletion: Ctrl+Backspace and Ctrl+Delete
map("i", "<C-BS>", "<C-w>", { desc = "Delete Word Backward (IDE: Ctrl+Backspace)" })
map("i", "<M-BS>", "<C-w>", { desc = "Delete Word Backward (IDE: Alt/Ctrl+Backspace)" })
map({ "n", "v" }, "<C-BS>", '"_db', { desc = "Delete Word Backward (IDE: Ctrl+Backspace)" })
map({ "n", "v" }, "<M-BS>", '"_db', { desc = "Delete Word Backward (IDE: Alt/Ctrl+Backspace)" })

map("i", "<C-Del>", '<C-o>"_dw', { desc = "Delete Word Forward (IDE: Ctrl+Delete)" })
map({ "n", "v" }, "<C-Del>", '"_dw', { desc = "Delete Word Forward (IDE: Ctrl+Delete)" })

-------------------------------------------------------------------------------
-- 2. CLIPBOARD OPERATIONS (Ctrl+C, Ctrl+X, Ctrl+V)
-------------------------------------------------------------------------------

-- Copy (Visual: selection; Normal/Insert: entire line like VS Code)
map("v", "<C-c>", '"+y', { desc = "Copy Selection (IDE: Ctrl+C)" })
map("n", "<C-c>", '"+yy', { desc = "Copy Current Line (IDE: Ctrl+C)" })
map("i", "<C-c>", '<Esc>"+yygi', { desc = "Copy Current Line (IDE: Ctrl+C)" })

-- Cut (Visual: selection; Normal/Insert: entire line like VS Code)
map("v", "<C-x>", '"+d', { desc = "Cut Selection (IDE: Ctrl+X)" })
map("n", "<C-x>", '"+dd', { desc = "Cut Current Line (IDE: Ctrl+X)" })
map("i", "<C-x>", '<Esc>"+ddi', { desc = "Cut Current Line (IDE: Ctrl+X)" })

-- Paste (Visual: replace selection; Normal/Insert: paste at cursor)
map("v", "<C-v>", '"+p', { desc = "Paste Over Selection (IDE: Ctrl+V)" })
map("n", "<C-v>", '"+p', { desc = "Paste (IDE: Ctrl+V)" })
map("i", "<C-v>", '<C-r>+', { desc = "Paste (IDE: Ctrl+V)" })

-------------------------------------------------------------------------------
-- 3. UNDO & REDO (Ctrl+Z, Ctrl+Y, Ctrl+Shift+Z)
-------------------------------------------------------------------------------

map("n", "<C-z>", "u", { desc = "Undo (IDE: Ctrl+Z)" })
map("i", "<C-z>", "<C-o>u", { desc = "Undo (IDE: Ctrl+Z)" })
map("v", "<C-z>", "<Esc>u", { desc = "Undo (IDE: Ctrl+Z)" })

map("n", "<C-y>", "<C-r>", { desc = "Redo (IDE: Ctrl+Y)" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Redo (IDE: Ctrl+Y)" })
map("v", "<C-y>", "<Esc><C-r>", { desc = "Redo (IDE: Ctrl+Y)" })

map({ "n", "i", "v" }, "<C-S-z>", "<C-r>", { desc = "Redo (IDE: Ctrl+Shift+Z)" })

-------------------------------------------------------------------------------
-- 4. SELECT ALL (Ctrl+A)
-------------------------------------------------------------------------------

map({ "n", "i", "v" }, "<C-a>", "<Esc>gg0vG$", { desc = "Select All (IDE: Ctrl+A)" })

-------------------------------------------------------------------------------
-- 5. FILE & PROJECT OPERATIONS (Save, Close, Palette, Sidebar)
-------------------------------------------------------------------------------

map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save File (IDE: Ctrl+S)" })
map({ "n", "i", "v" }, "<C-S-s>", ":w ", { desc = "Save File As (IDE: Ctrl+Shift+S)" })
map({ "n", "i", "v" }, "<C-w>", "<cmd>confirm bdelete<CR>", { desc = "Close Editor Tab (IDE: Ctrl+W)" })
map({ "n", "i", "v" }, "<C-S-w>", "<cmd>confirm q<CR>", { desc = "Close Window (IDE: Ctrl+Shift+W)" })
map({ "n", "i", "v" }, "<C-n>", "<cmd>enew<CR>", { desc = "New File (IDE: Ctrl+N)" })

-- Quick Open File & Command Palette
map({ "n", "i", "v" }, "<C-p>", "<cmd>Telescope find_files<CR>", { desc = "Quick Open File (IDE: Ctrl+P)" })
map({ "n", "i", "v" }, "<C-o>", "<cmd>Telescope find_files<CR>", { desc = "Open File (IDE: Ctrl+O)" })
map({ "n", "i", "v" }, "<C-S-p>", "<cmd>Telescope commands<CR>", { desc = "Command Palette (IDE: Ctrl+Shift+P)" })
map({ "n", "i", "v" }, "<F1>", "<cmd>Telescope commands<CR>", { desc = "Command Palette (IDE: F1)" })

-- Sidebar / File Explorer
map({ "n", "i", "v" }, "<C-b>", "<cmd>Neotree toggle<CR>", { desc = "Toggle Sidebar / Explorer (IDE: Ctrl+B)" })
map({ "n", "i", "v" }, "<C-S-e>", "<cmd>Neotree focus<CR>", { desc = "Focus File Explorer (IDE: Ctrl+Shift+E)" })
map({ "n", "i", "v" }, "<C-\\>", "<cmd>vsplit<CR>", { desc = "Split Editor Vertically (IDE: Ctrl+\\)" })

-- Terminal & Problems Panel
map({ "n", "t", "i" }, "<C-`>", "<cmd>ToggleTerm direction=float<CR>", { desc = "Toggle Integrated Terminal (IDE: Ctrl+`)" })
map({ "n", "t", "i" }, "<C-~>", "<cmd>ToggleTerm direction=float<CR>", { desc = "Toggle Integrated Terminal (IDE: Ctrl+~)" })
map({ "n", "i", "v" }, "<C-S-m>", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Toggle Problems / Diagnostics (IDE: Ctrl+Shift+M)" })

-- Symbols & Outline
map({ "n", "i", "v" }, "<C-S-o>", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Go to Symbol in File (IDE: Ctrl+Shift+O)" })
map({ "n", "i", "v" }, "<C-t>", "<cmd>Telescope lsp_workspace_symbols<CR>", { desc = "Go to Symbol in Workspace (IDE: Ctrl+T)" })

-- Go to Line (Ctrl+G)
map({ "n", "i", "v" }, "<C-g>", function()
  vim.ui.input({ prompt = "Go to Line: " }, function(input)
    if input and tonumber(input) then
      vim.cmd(tostring(tonumber(input)))
    end
  end)
end, { desc = "Go to Line (IDE: Ctrl+G)" })

-------------------------------------------------------------------------------
-- 6. SEARCH & REPLACE (Ctrl+F, Ctrl+H, Ctrl+Shift+F, Ctrl+Shift+H)
-------------------------------------------------------------------------------

map({ "n", "i", "v" }, "<C-f>", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Find in File (IDE: Ctrl+F)" })
map({ "n", "i", "v" }, "<C-h>", replace_current_file, { desc = "Find & Replace in File (IDE: Ctrl+H)" })
map({ "n", "i", "v" }, "<C-S-f>", "<cmd>Telescope live_grep<CR>", { desc = "Find in Files (IDE: Ctrl+Shift+F)" })
map({ "n", "i", "v" }, "<C-S-h>", "<cmd>GrugFar<CR>", { desc = "Find & Replace in Files (IDE: Ctrl+Shift+H)" })

-- Find Next / Previous (F3 / Shift+F3)
map({ "n", "i", "v" }, "<F3>", "n", { desc = "Find Next (IDE: F3)" })
map({ "n", "i", "v" }, "<S-F3>", "N", { desc = "Find Previous (IDE: Shift+F3)" })

-------------------------------------------------------------------------------
-- 7. LINE & TEXT EDITING (Move, Duplicate, Delete Line, Comments)
-------------------------------------------------------------------------------

-- Move Line / Selection Up & Down (Alt+Down / Alt+Up)
map("n", "<M-Down>", "<cmd>m .+1<CR>==", { desc = "Move Line Down (IDE: Alt+Down)" })
map("n", "<M-Up>", "<cmd>m .-2<CR>==", { desc = "Move Line Up (IDE: Alt+Up)" })
map("i", "<M-Down>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move Line Down (IDE: Alt+Down)" })
map("i", "<M-Up>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move Line Up (IDE: Alt+Up)" })
map("v", "<M-Down>", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down (IDE: Alt+Down)" })
map("v", "<M-Up>", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up (IDE: Alt+Up)" })

-- Duplicate Line / Selection Up & Down (Shift+Alt+Down / Shift+Alt+Up)
map("n", "<M-S-Down>", "<cmd>t.<CR>", { desc = "Duplicate Line Down (IDE: Shift+Alt+Down)" })
map("n", "<M-S-Up>", "<cmd>t.-1<CR>", { desc = "Duplicate Line Up (IDE: Shift+Alt+Up)" })
map("i", "<M-S-Down>", "<Esc><cmd>t.<CR>gi", { desc = "Duplicate Line Down (IDE: Shift+Alt+Down)" })
map("i", "<M-S-Up>", "<Esc><cmd>t.-1<CR>gi", { desc = "Duplicate Line Up (IDE: Shift+Alt+Up)" })
map("v", "<M-S-Down>", ":'<,'>y<CR>'>pgv", { desc = "Duplicate Selection Down (IDE: Shift+Alt+Down)" })
map("v", "<M-S-Up>", ":'<,'>y<CR>'<Pgv", { desc = "Duplicate Selection Up (IDE: Shift+Alt+Up)" })

-- Delete Line (Ctrl+Shift+K)
map("n", "<C-S-k>", '"_dd', { desc = "Delete Line (IDE: Ctrl+Shift+K)" })
map("i", "<C-S-k>", '<Esc>"_ddgi', { desc = "Delete Line (IDE: Ctrl+Shift+K)" })
map("v", "<C-S-k>", '"_d', { desc = "Delete Line (IDE: Ctrl+Shift+K)" })

-- Insert Line Below / Above (Ctrl+Enter / Ctrl+Shift+Enter)
map("n", "<C-CR>", "o<Esc>", { desc = "Insert Line Below (IDE: Ctrl+Enter)" })
map("i", "<C-CR>", "<Esc>o", { desc = "Insert Line Below (IDE: Ctrl+Enter)" })
map("n", "<C-S-CR>", "O<Esc>", { desc = "Insert Line Above (IDE: Ctrl+Shift+Enter)" })
map("i", "<C-S-CR>", "<Esc>O", { desc = "Insert Line Above (IDE: Ctrl+Shift+Enter)" })

-- Line Commenting (Ctrl+/ and Ctrl+_)
map("n", "<C-/>", "<cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>", { desc = "Toggle Line Comment (IDE: Ctrl+/)" })
map("n", "<C-_>", "<cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>", { desc = "Toggle Line Comment (IDE: Ctrl+_)" })
map("v", "<C-/>", ":<C-u>lua require('mini.comment').toggle_lines(vim.fn.line(\"'<\"), vim.fn.line(\"'>\"))<CR>gv", { desc = "Toggle Comment (IDE: Ctrl+/)" })
map("v", "<C-_>", ":<C-u>lua require('mini.comment').toggle_lines(vim.fn.line(\"'<\"), vim.fn.line(\"'>\"))<CR>gv", { desc = "Toggle Comment (IDE: Ctrl+_)" })
map("i", "<C-/>", "<Esc><cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>a", { desc = "Toggle Line Comment (IDE: Ctrl+/)" })
map("i", "<C-_>", "<Esc><cmd>lua require('mini.comment').toggle_lines(vim.fn.line('.'), vim.fn.line('.'))<CR>a", { desc = "Toggle Line Comment (IDE: Ctrl+_)" })

-- Indentation (Tab, Shift+Tab, Ctrl+], Ctrl+[)
map("v", "<Tab>", ">gv", { desc = "Indent Selection (Tab)" })
map("v", "<S-Tab>", "<gv", { desc = "Outdent Selection (Shift+Tab)" })
map("n", "<S-Tab>", "<<", { desc = "Outdent Line (Shift+Tab)" })
map("i", "<S-Tab>", "<C-d>", { desc = "Outdent Line (Shift+Tab)" })
map("n", "<C-]>", ">>", { desc = "Indent Line (IDE: Ctrl+])" })
map("v", "<C-]>", ">gv", { desc = "Indent Selection (IDE: Ctrl+])" })
map("i", "<C-]>", "<C-t>", { desc = "Indent Line (IDE: Ctrl+])" })

-------------------------------------------------------------------------------
-- 8. CURSOR NAVIGATION & WORD JUMPING
-------------------------------------------------------------------------------

-- Home & End
map("n", "<Home>", smart_home, { desc = "Smart Home (Start of Indent/Line)" })
map("v", "<Home>", smart_home, { desc = "Smart Home (Start of Indent/Line)" })
map("i", "<Home>", "<C-o>^", { desc = "Start of Line (IDE: Home)" })
map("n", "<End>", "$", { desc = "End of Line (IDE: End)" })
map("v", "<End>", "$", { desc = "End of Line (IDE: End)" })
map("i", "<End>", "<End>", { desc = "End of Line (IDE: End)" })

-- File Start & End (Ctrl+Home, Ctrl+End)
map({ "n", "v" }, "<C-Home>", "gg", { desc = "Beginning of File (IDE: Ctrl+Home)" })
map("i", "<C-Home>", "<C-o>gg", { desc = "Beginning of File (IDE: Ctrl+Home)" })
map({ "n", "v" }, "<C-End>", "G", { desc = "End of File (IDE: Ctrl+End)" })
map("i", "<C-End>", "<C-o>G", { desc = "End of File (IDE: Ctrl+End)" })

-- Word Left & Word Right (Ctrl+Left, Ctrl+Right)
map({ "n", "v" }, "<C-Left>", "b", { desc = "Word Left (IDE: Ctrl+Left)" })
map("i", "<C-Left>", "<C-o>b", { desc = "Word Left (IDE: Ctrl+Left)" })
map({ "n", "v" }, "<C-Right>", "w", { desc = "Word Right (IDE: Ctrl+Right)" })
map("i", "<C-Right>", "<C-o>w", { desc = "Word Right (IDE: Ctrl+Right)" })

-- Navigation History: Back & Forward (Alt+Left / Alt+Right)
map("n", "<M-Left>", "<C-o>", { desc = "Navigate Back (IDE: Alt+Left)" })
map("n", "<M-Right>", "<C-i>", { desc = "Navigate Forward (IDE: Alt+Right)" })

-------------------------------------------------------------------------------
-- 9. SHIFT + ARROW TEXT SELECTION (VS Code Native Selection)
-------------------------------------------------------------------------------

-- Shift + Arrows: Start / Extend Selection
map("n", "<S-Left>", "v<Left>", { desc = "Select Left" })
map("n", "<S-Right>", "v<Right>", { desc = "Select Right" })
map("n", "<S-Up>", "v<Up>", { desc = "Select Up" })
map("n", "<S-Down>", "v<Down>", { desc = "Select Down" })

map("i", "<S-Left>", "<Esc>v<Left>", { desc = "Select Left" })
map("i", "<S-Right>", "<Esc>v<Right>", { desc = "Select Right" })
map("i", "<S-Up>", "<Esc>v<Up>", { desc = "Select Up" })
map("i", "<S-Down>", "<Esc>v<Down>", { desc = "Select Down" })

map("v", "<S-Left>", "<Left>", { desc = "Extend Selection Left" })
map("v", "<S-Right>", "<Right>", { desc = "Extend Selection Right" })
map("v", "<S-Up>", "<Up>", { desc = "Extend Selection Up" })
map("v", "<S-Down>", "<Down>", { desc = "Extend Selection Down" })

-- Shift + Home / End: Select to Start / End of line
map("n", "<S-Home>", "v^", { desc = "Select to Start of Line" })
map("n", "<S-End>", "v$", { desc = "Select to End of Line" })
map("i", "<S-Home>", "<Esc>v^", { desc = "Select to Start of Line" })
map("i", "<S-End>", "<Esc>v$", { desc = "Select to End of Line" })
map("v", "<S-Home>", "^", { desc = "Extend Selection to Start of Line" })
map("v", "<S-End>", "$", { desc = "Extend Selection to End of Line" })

-- Ctrl + Shift + Left / Right: Select Word
map("n", "<C-S-Left>", "vb", { desc = "Select Word Left" })
map("n", "<C-S-Right>", "ve", { desc = "Select Word Right" })
map("i", "<C-S-Left>", "<Esc>vb", { desc = "Select Word Left" })
map("i", "<C-S-Right>", "<Esc>ve", { desc = "Select Word Right" })
map("v", "<C-S-Left>", "b", { desc = "Extend Selection Word Left" })
map("v", "<C-S-Right>", "e", { desc = "Extend Selection Word Right" })

-- Ctrl + Shift + Home / End: Select to Start / End of Document
map("n", "<C-S-Home>", "vgg", { desc = "Select to Beginning of File" })
map("n", "<C-S-End>", "vG$", { desc = "Select to End of File" })
map("i", "<C-S-Home>", "<Esc>vgg", { desc = "Select to Beginning of File" })
map("i", "<C-S-End>", "<Esc>vG$", { desc = "Select to End of File" })
map("v", "<C-S-Home>", "gg", { desc = "Extend Selection to Beginning of File" })
map("v", "<C-S-End>", "G$", { desc = "Extend Selection to End of File" })

-------------------------------------------------------------------------------
-- 10. TABS & BUFFER NAVIGATION (Ctrl+Tab, Alt+1..9, Close All)
-------------------------------------------------------------------------------

map({ "n", "i" }, "<C-Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab (IDE: Ctrl+Tab)" })
map({ "n", "i" }, "<C-S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Tab (IDE: Ctrl+Shift+Tab)" })
map({ "n", "i" }, "<C-PageDown>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab (IDE: Ctrl+PageDown)" })
map({ "n", "i" }, "<C-PageUp>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous Tab (IDE: Ctrl+PageUp)" })

-- Alt+1..9 to jump directly to tab 1..9
for i = 1, 9 do
  map({ "n", "i" }, "<M-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "Go to Tab " .. i })
end

-- Close all editors (Ctrl+K W / Ctrl+K Ctrl+W)
map({ "n", "i", "v" }, "<C-k>w", "<cmd>confirm bufdo bdelete<CR>", { desc = "Close All Editors (IDE: Ctrl+K W)" })
map({ "n", "i", "v" }, "<C-k><C-w>", "<cmd>confirm bufdo bdelete<CR>", { desc = "Close All Editors (IDE: Ctrl+K Ctrl+W)" })
map({ "n", "i", "v" }, "<C-k><C-\\>", "<cmd>split<CR>", { desc = "Split Editor Horizontally (IDE: Ctrl+K Ctrl+\\)" })

-------------------------------------------------------------------------------
-- 11. LSP & REFACTORING HOTKEYS (F12, F2, Alt+Enter, etc.)
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
map({ "n", "i" }, "<C-k><C-i>", vim.lsp.buf.hover, { desc = "Hover Documentation (IDE: Ctrl+K Ctrl+I)" })
map({ "n", "i" }, "<C-k>", vim.lsp.buf.hover, { desc = "Hover Documentation (IDE: Ctrl+K)" })
map({ "n", "i" }, "<C-S-Space>", vim.lsp.buf.signature_help, { desc = "Parameter Hints (IDE: Ctrl+Shift+Space)" })

-------------------------------------------------------------------------------
-- 12. KEYBOARD SHORTCUTS CHEATSHEET (Ctrl+K Ctrl+S)
-------------------------------------------------------------------------------

map({ "n", "i", "v" }, "<C-k><C-s>", function() require("config.cheatsheet").toggle() end, { desc = "Toggle Shortcuts Cheatsheet (IDE: Ctrl+K Ctrl+S)" })
map("n", "<leader>?", function() require("config.cheatsheet").toggle() end, { desc = "Toggle Shortcuts Cheatsheet" })

-------------------------------------------------------------------------------
-- 13. VIM-NATIVE ERGONOMIC SHORTCUTS (<Space> Leader)
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
