return {
  {
    "vscode-keymaps",
    name = "vscode-keymaps",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      local map = vim.keymap.set
      local opt = vim.opt

      -------------------------------------------------------------------------------
      -- 0. CORE VIM OPTIONS FOR VS CODE SELECTION & NAVIGATION
      -------------------------------------------------------------------------------
      -- Backspace across indents, newlines, and insert starts
      opt.backspace = { "indent", "eol", "start" }
      opt.whichwrap:append("<,>,[,],h,l")
      opt.virtualedit = "onemore"

      -- Shift+Arrow visual selection and mouse like VS Code
      opt.keymodel = { "startsel", "stopsel" }
      opt.selection = "inclusive"
      opt.selectmode = { "mouse", "key" }

      -- System clipboard integration
      opt.clipboard = "unnamedplus"

      -------------------------------------------------------------------------------
      -- HELPER FUNCTIONS FOR VS CODE EDITING BEHAVIOR
      -------------------------------------------------------------------------------

      --- Smart Backspace in Normal Mode: deletes character before cursor; joins previous line at col 0
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

      --- Smart Delete in Normal Mode: deletes character under cursor; joins next line at line end
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

      --- Smart Home: toggle between first non-blank character and column 0
      local function smart_home()
        local col = vim.fn.col(".")
        local first_nonblank = vim.fn.indent(".") + 1
        if col ~= first_nonblank then
          vim.cmd("normal! ^")
        else
          vim.cmd("normal! 0")
        end
      end

      --- Quick Open File (Ctrl+P / Ctrl+O)
      local function quick_open()
        local ok_smart, telescope = pcall(require, "telescope")
        if ok_smart and telescope.extensions and telescope.extensions.smart_open then
          telescope.extensions.smart_open.smart_open()
          return
        end
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.picker then
          snacks.picker.smart()
          return
        end
        if ok_smart then
          telescope.builtin.find_files()
          return
        end
        vim.cmd("e #")
      end

      --- Command Palette (Ctrl+Shift+P / F1)
      local function command_palette()
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.picker then
          snacks.picker.commands()
          return
        end
        local ok_tel, telescope = pcall(require, "telescope.builtin")
        if ok_tel then
          telescope.commands()
          return
        end
      end

      --- Toggle Primary Sidebar / Explorer (Ctrl+B)
      local function toggle_explorer()
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.explorer then
          snacks.explorer()
          return
        end
        local ok_neotree = pcall(vim.cmd, "Neotree toggle")
        if not ok_neotree then
          vim.cmd("Lex")
        end
      end

      --- Toggle Integrated Floating Terminal (Ctrl+`)
      local function toggle_terminal()
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.terminal then
          snacks.terminal()
          return
        end
        pcall(vim.cmd, "ToggleTerm direction=float")
      end

      --- Toggle Diagnostics Drawer (Ctrl+Shift+M)
      local function toggle_problems()
        local ok_trouble = pcall(vim.cmd, "Trouble diagnostics toggle")
        if not ok_trouble then
          local ok_snacks, snacks = pcall(require, "snacks")
          if ok_snacks and snacks.picker then
            snacks.picker.diagnostics()
          end
        end
      end

      --- Find in current buffer (Ctrl+F)
      local function find_in_file()
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.picker then
          snacks.picker.lines()
          return
        end
        local ok_tel, tel = pcall(require, "telescope.builtin")
        if ok_tel then
          tel.current_buffer_fuzzy_find()
          return
        end
        vim.cmd("normal! /")
      end

      --- Find in workspace / files (Ctrl+Shift+F)
      local function find_in_project()
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.picker then
          snacks.picker.grep()
          return
        end
        local ok_tel, tel = pcall(require, "telescope.builtin")
        if ok_tel then
          tel.live_grep()
          return
        end
      end

      --- Find and Replace in current file (Ctrl+H)
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

      --- Find and Replace across project (Ctrl+Shift+H)
      local function replace_global()
        local ok, grug = pcall(require, "grug-far")
        if ok then
          grug.open()
        else
          find_in_project()
        end
      end

      --- Go to Line (Ctrl+G)
      local function goto_line()
        vim.ui.input({ prompt = "Go to Line: " }, function(input)
          if input and tonumber(input) then
            vim.cmd(tostring(tonumber(input)))
          end
        end)
      end

      --- LSP Rename with live-rename fallback
      local function lsp_rename()
        local ok, live_rename = pcall(require, "live-rename")
        if ok then
          live_rename.rename()
        else
          vim.lsp.buf.rename()
        end
      end

      --- Format document
      local function format_doc()
        local ok, conform = pcall(require, "conform")
        if ok then
          conform.format({ async = true, lsp_fallback = true })
        else
          vim.lsp.buf.format({ async = true })
        end
      end

      --- Floating Shortcuts Cheatsheet Modal (Ctrl+K Ctrl+S)
      local cheatsheet_win, cheatsheet_buf
      local function toggle_cheatsheet()
        if cheatsheet_win and vim.api.nvim_win_is_valid(cheatsheet_win) then
          vim.api.nvim_win_close(cheatsheet_win, true)
          cheatsheet_win = nil
          return
        end

        local content = {
          " ╔════════════════════════════════════════════════════════════════════════════════════╗",
          " ║                          ⚡ VS CODE HOTKEYS CHEATSHEET                              ║",
          " ╚════════════════════════════════════════════════════════════════════════════════════╝",
          "",
          " 📁 FILE & PROJECT OPERATIONS",
          "   Ctrl + P / Ctrl + O      Quick Open file by name (Smart Open / Telescope)",
          "   Ctrl + Shift + P / F1    Command Palette (Search all commands)",
          "   Ctrl + S / Ctrl+Shift+S  Save file / Save file As",
          "   Ctrl + W / Ctrl+K W      Close active editor tab / Close all editor tabs",
          "   Ctrl + N                 New empty file / buffer",
          "   Ctrl + B / Ctrl + \\      Toggle File Explorer / Split Editor Vertically",
          "   Ctrl + Shift + E         Focus File Explorer sidebar",
          "   Ctrl + Shift + O         Go to Symbol in File (Outline)",
          "   Ctrl + T                 Go to Symbol in Workspace",
          "   Ctrl + G                 Go to Line number",
          "",
          " ✏️ EDITING, SELECTION & CLIPBOARD",
          "   Backspace / Delete       Delete left / right symbol in ALL modes (VS Code)",
          "   Ctrl + Backspace / Del   Delete entire word backward / forward",
          "   Ctrl + Shift + K         Delete entire line",
          "   Shift + Arrows           Select text (Left / Right / Up / Down)",
          "   Shift + Home / End       Select to start / end of line",
          "   Ctrl + Shift + Left/Rgt  Select word backward / forward",
          "   Ctrl + Shift + Home/End  Select to top / bottom of document",
          "   Ctrl + A                 Select All",
          "   Ctrl + C / Ctrl + X      Copy / Cut selection (or current line if no selection)",
          "   Ctrl + V                 Paste from system clipboard",
          "   Ctrl + Z                 Undo (Normal, Insert, Visual)",
          "   Ctrl + Y / Ctrl+Shift+Z  Redo (Normal, Insert, Visual)",
          "   Ctrl + / (Ctrl + _)      Toggle Line Comment (Normal, Insert, Visual)",
          "   Alt + Up / Down          Move Line / Selection Up / Down",
          "   Shift + Alt + Down / Up  Duplicate Line / Selection Down / Up",
          "   Ctrl + Enter / C-S-Enter Insert line below / above",
          "   Tab / Shift + Tab        Indent / Outdent line or selection",
          "   Home / End               Start / End of line",
          "   Ctrl + Home / Ctrl + End Top / Bottom of file",
          "",
          " 🔍 SEARCH & REPLACE",
          "   Ctrl + F                 Find text in current buffer",
          "   Ctrl + H                 Find and Replace in current buffer (grug-far)",
          "   Ctrl + Shift + F         Global Find in Files (project-wide live grep)",
          "   Ctrl + Shift + H         Find and Replace across all files (grug-far)",
          "   F3 / Shift + F3          Find Next / Previous match",
          "",
          " 💡 CODE INTELLIGENCE, LSP & REFACTORING",
          "   F12                      Go to Definition (LSP)",
          "   Shift + F12 / Alt + F12  Find All References (LSP)",
          "   Ctrl + F12               Go to Implementation (LSP)",
          "   F2                       Live Rename Symbol across entire workspace",
          "   Ctrl + . / Alt + Enter   Quick Fix / Code Actions",
          "   Shift + Alt + F          Format Document",
          "   Ctrl + Shift + I         Format Document",
          "   F8 / Shift + F8          Jump to Next / Previous Problem (Error / Warning)",
          "   Ctrl + K / Ctrl + K C-I  Hover Documentation / Type info",
          "   Ctrl + Shift + Space     Parameter & Function Signature Hints",
          "",
          " 🖥️ TERMINAL, PROBLEMS & TABS",
          "   Ctrl + ` / Ctrl + ~      Toggle floating integrated terminal",
          "   Ctrl + Shift + M         Toggle Problems / Diagnostics drawer",
          "   Ctrl + Tab / C-Shift-Tab Next / Previous editor tab",
          "   Alt + 1 .. 9             Jump directly to Tab 1 through 9",
          "   Alt + Left / Alt + Right Navigate Back / Forward in history",
          "   Ctrl + K Ctrl + S        Toggle this VS Code Hotkeys Cheatsheet",
          "   <Space> (Leader)         LazyVim standard leader menus",
          "",
          " ── Press <Esc> or q to close ─────────────────────────────────────────────────────────",
        }

        cheatsheet_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(cheatsheet_buf, 0, -1, false, content)
        vim.bo[cheatsheet_buf].modifiable = false
        vim.bo[cheatsheet_buf].filetype = "help"

        local width = 88
        local height = math.min(#content + 1, vim.o.lines - 4)
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        local win_opts = {
          relative = "editor",
          width = width,
          height = height,
          row = row,
          col = col,
          style = "minimal",
          border = "rounded",
          title = " ⚡ VS Code Hotkeys ",
          title_pos = "center",
        }

        cheatsheet_win = vim.api.nvim_open_win(cheatsheet_buf, true, win_opts)
        vim.wo[cheatsheet_win].wrap = false
        vim.wo[cheatsheet_win].cursorline = true

        local close_keys = { "<Esc>", "q" }
        for _, key in ipairs(close_keys) do
          vim.keymap.set("n", key, function()
            if cheatsheet_win and vim.api.nvim_win_is_valid(cheatsheet_win) then
              vim.api.nvim_win_close(cheatsheet_win, true)
              cheatsheet_win = nil
            end
          end, { buffer = cheatsheet_buf, silent = true, nowait = true })
        end
      end

      -------------------------------------------------------------------------------
      -- 1. UNIVERSAL VS CODE CORE EDITING & BACKSPACE / DELETE
      -------------------------------------------------------------------------------
      -- Backspace in all modes
      map("n", "<BS>", smart_backspace_normal, { desc = "Backspace (IDE: Delete left)" })
      map("n", "<C-h>", smart_backspace_normal, { desc = "Backspace (IDE: Delete left)" })
      map({ "v", "x", "s" }, "<BS>", '"_d', { desc = "Delete Selection (IDE: Backspace)" })
      map({ "v", "x", "s" }, "<C-h>", '"_d', { desc = "Delete Selection (IDE: Backspace)" })
      map("i", "<BS>", "<BS>", { desc = "Backspace" })
      map("i", "<C-h>", "<BS>", { desc = "Backspace" })

      -- Delete in all modes
      map("n", "<Del>", smart_delete_normal, { desc = "Delete (IDE: Delete right)" })
      map({ "v", "x", "s" }, "<Del>", '"_d', { desc = "Delete Selection (IDE: Delete)" })
      map("i", "<Del>", "<Del>", { desc = "Delete Forward" })

      -- Word Deletion: Ctrl+Backspace and Ctrl+Delete
      map("i", "<C-BS>", "<C-w>", { desc = "Delete Word Backward (IDE: Ctrl+Backspace)" })
      map("i", "<M-BS>", "<C-w>", { desc = "Delete Word Backward (IDE: Alt+Backspace)" })
      map({ "n", "v" }, "<C-BS>", '"_db', { desc = "Delete Word Backward (IDE: Ctrl+Backspace)" })
      map({ "n", "v" }, "<M-BS>", '"_db', { desc = "Delete Word Backward (IDE: Alt+Backspace)" })

      map("i", "<C-Del>", '<C-o>"_dw', { desc = "Delete Word Forward (IDE: Ctrl+Delete)" })
      map({ "n", "v" }, "<C-Del>", '"_dw', { desc = "Delete Word Forward (IDE: Ctrl+Delete)" })

      -------------------------------------------------------------------------------
      -- 2. CLIPBOARD OPERATIONS (Ctrl+C, Ctrl+X, Ctrl+V)
      -------------------------------------------------------------------------------
      -- Copy (Visual: selection; Normal/Insert: entire line)
      map("v", "<C-c>", '"+y', { desc = "Copy Selection (IDE: Ctrl+C)" })
      map("n", "<C-c>", '"+yy', { desc = "Copy Current Line (IDE: Ctrl+C)" })
      map("i", "<C-c>", '<Esc>"+yygi', { desc = "Copy Current Line (IDE: Ctrl+C)" })

      -- Cut (Visual: selection; Normal/Insert: entire line)
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
      map({ "n", "i", "v" }, "<C-p>", quick_open, { desc = "Quick Open File (IDE: Ctrl+P)" })
      map({ "n", "i", "v" }, "<C-o>", quick_open, { desc = "Open File (IDE: Ctrl+O)" })
      map({ "n", "i", "v" }, "<C-S-p>", command_palette, { desc = "Command Palette (IDE: Ctrl+Shift+P)" })
      map({ "n", "i", "v" }, "<F1>", command_palette, { desc = "Command Palette (IDE: F1)" })

      -- Sidebar / File Explorer & Splits
      map({ "n", "i", "v" }, "<C-b>", toggle_explorer, { desc = "Toggle Sidebar / Explorer (IDE: Ctrl+B)" })
      map({ "n", "i", "v" }, "<C-S-e>", toggle_explorer, { desc = "Focus File Explorer (IDE: Ctrl+Shift+E)" })
      map({ "n", "i", "v" }, "<C-\\>", "<cmd>vsplit<CR>", { desc = "Split Editor Vertically (IDE: Ctrl+\\)" })

      -- Terminal & Problems Panel
      map({ "n", "t", "i" }, "<C-`>", toggle_terminal, { desc = "Toggle Integrated Terminal (IDE: Ctrl+`)" })
      map({ "n", "t", "i" }, "<C-~>", toggle_terminal, { desc = "Toggle Integrated Terminal (IDE: Ctrl+~)" })
      map({ "n", "i", "v" }, "<C-S-m>", toggle_problems, { desc = "Toggle Problems / Diagnostics (IDE: Ctrl+Shift+M)" })

      -- Symbols & Outline
      map({ "n", "i", "v" }, "<C-S-o>", function()
        local ok, snacks = pcall(require, "snacks")
        if ok and snacks.picker then
          snacks.picker.lsp_symbols()
        else
          pcall(function() require("telescope.builtin").lsp_document_symbols() end)
        end
      end, { desc = "Go to Symbol in File (IDE: Ctrl+Shift+O)" })

      map({ "n", "i", "v" }, "<C-t>", function()
        local ok, snacks = pcall(require, "snacks")
        if ok and snacks.picker then
          snacks.picker.lsp_workspace_symbols()
        else
          pcall(function() require("telescope.builtin").lsp_workspace_symbols() end)
        end
      end, { desc = "Go to Symbol in Workspace (IDE: Ctrl+T)" })

      -- Go to Line (Ctrl+G)
      map({ "n", "i", "v" }, "<C-g>", goto_line, { desc = "Go to Line (IDE: Ctrl+G)" })

      -------------------------------------------------------------------------------
      -- 6. SEARCH & REPLACE (Ctrl+F, Ctrl+H, Ctrl+Shift+F, Ctrl+Shift+H)
      -------------------------------------------------------------------------------
      map({ "n", "i", "v" }, "<C-f>", find_in_file, { desc = "Find in File (IDE: Ctrl+F)" })
      map({ "n", "i", "v" }, "<C-h>", replace_current_file, { desc = "Find & Replace in File (IDE: Ctrl+H)" })
      map({ "n", "i", "v" }, "<C-S-f>", find_in_project, { desc = "Find in Files (IDE: Ctrl+Shift+F)" })
      map({ "n", "i", "v" }, "<C-S-h>", replace_global, { desc = "Find & Replace in Files (IDE: Ctrl+Shift+H)" })

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
      map("n", "<C-/>", "<cmd>normal gcc<CR>", { desc = "Toggle Line Comment (IDE: Ctrl+/)" })
      map("n", "<C-_>", "<cmd>normal gcc<CR>", { desc = "Toggle Line Comment (IDE: Ctrl+_)" })
      map("v", "<C-/>", "gc", { remap = true, desc = "Toggle Comment (IDE: Ctrl+/)" })
      map("v", "<C-_>", "gc", { remap = true, desc = "Toggle Comment (IDE: Ctrl+_)" })
      map("i", "<C-/>", "<Esc>gcca", { remap = true, desc = "Toggle Line Comment (IDE: Ctrl+/)" })
      map("i", "<C-_>", "<Esc>gcca", { remap = true, desc = "Toggle Line Comment (IDE: Ctrl+_)" })

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

      map("n", "<S-Home>", "v^", { desc = "Select to Start of Line" })
      map("n", "<S-End>", "v$", { desc = "Select to End of Line" })
      map("i", "<S-Home>", "<Esc>v^", { desc = "Select to Start of Line" })
      map("i", "<S-End>", "<Esc>v$", { desc = "Select to End of Line" })
      map("v", "<S-Home>", "^", { desc = "Extend Selection to Start of Line" })
      map("v", "<S-End>", "$", { desc = "Extend Selection to End of Line" })

      map("n", "<C-S-Left>", "vb", { desc = "Select Word Left" })
      map("n", "<C-S-Right>", "ve", { desc = "Select Word Right" })
      map("i", "<C-S-Left>", "<Esc>vb", { desc = "Select Word Left" })
      map("i", "<C-S-Right>", "<Esc>ve", { desc = "Select Word Right" })
      map("v", "<C-S-Left>", "b", { desc = "Extend Selection Word Left" })
      map("v", "<C-S-Right>", "e", { desc = "Extend Selection Word Right" })

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

      for i = 1, 9 do
        map({ "n", "i" }, "<M-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "Go to Tab " .. i })
      end

      map({ "n", "i", "v" }, "<C-k>w", "<cmd>confirm bufdo bdelete<CR>", { desc = "Close All Editors (IDE: Ctrl+K W)" })
      map({ "n", "i", "v" }, "<C-k><C-w>", "<cmd>confirm bufdo bdelete<CR>", { desc = "Close All Editors (IDE: Ctrl+K Ctrl+W)" })
      map({ "n", "i", "v" }, "<C-k><C-\\>", "<cmd>split<CR>", { desc = "Split Editor Horizontally (IDE: Ctrl+K Ctrl+\\)" })

      -------------------------------------------------------------------------------
      -- 11. LSP & REFACTORING HOTKEYS (F12, F2, Alt+Enter, etc.)
      -------------------------------------------------------------------------------
      map({ "n", "i" }, "<F12>", vim.lsp.buf.definition, { desc = "Go to Definition (IDE: F12)" })
      map({ "n", "i" }, "<S-F12>", function()
        local ok, snacks = pcall(require, "snacks")
        if ok and snacks.picker then
          snacks.picker.lsp_references()
        else
          pcall(function() require("telescope.builtin").lsp_references() end)
        end
      end, { desc = "Find All References (IDE: Shift+F12)" })
      map({ "n", "i" }, "<M-F12>", function()
        local ok, snacks = pcall(require, "snacks")
        if ok and snacks.picker then
          snacks.picker.lsp_references()
        else
          pcall(function() require("telescope.builtin").lsp_references() end)
        end
      end, { desc = "Find All References (IDE: Alt+F12)" })
      map({ "n", "i" }, "<C-F12>", vim.lsp.buf.implementation, { desc = "Go to Implementation (IDE: Ctrl+F12)" })
      map({ "n", "i" }, "<F2>", lsp_rename, { desc = "Rename Symbol (IDE: F2)" })
      map({ "n", "i", "v" }, "<M-CR>", vim.lsp.buf.code_action, { desc = "Quick Fix / Code Action (IDE: Alt+Enter)" })
      map({ "n", "i", "v" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Quick Fix / Code Action (IDE: Ctrl+.)" })
      map({ "n", "i", "v" }, "<M-S-f>", format_doc, { desc = "Format Document (IDE: Shift+Alt+F)" })
      map({ "n", "i", "v" }, "<C-S-i>", format_doc, { desc = "Format Document (IDE: Ctrl+Shift+I)" })
      map({ "n", "i" }, "<F8>", vim.diagnostic.goto_next, { desc = "Next Problem (IDE: F8)" })
      map({ "n", "i" }, "<S-F8>", vim.diagnostic.goto_prev, { desc = "Previous Problem (IDE: Shift+F8)" })
      map({ "n", "i" }, "<C-k><C-i>", vim.lsp.buf.hover, { desc = "Hover Documentation (IDE: Ctrl+K Ctrl+I)" })
      map({ "n", "i" }, "<C-k>", vim.lsp.buf.hover, { desc = "Hover Documentation (IDE: Ctrl+K)" })
      map({ "n", "i" }, "<C-S-Space>", vim.lsp.buf.signature_help, { desc = "Parameter Hints (IDE: Ctrl+Shift+Space)" })

      -------------------------------------------------------------------------------
      -- 12. KEYBOARD SHORTCUTS CHEATSHEET (Ctrl+K Ctrl+S)
      -------------------------------------------------------------------------------
      map({ "n", "i", "v" }, "<C-k><C-s>", toggle_cheatsheet, { desc = "Toggle Shortcuts Cheatsheet (IDE: Ctrl+K Ctrl+S)" })
      map("n", "<leader>?", toggle_cheatsheet, { desc = "Toggle Shortcuts Cheatsheet" })
    end,
  },
}
