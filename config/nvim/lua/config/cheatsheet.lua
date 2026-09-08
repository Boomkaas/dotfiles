local M = {}

local buf, win

function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
    return
  end

  local content = {
    " ╔════════════════════════════════════════════════════════════════════════════════════╗",
    " ║                          ⚡ NEOCONFIG IDE HOTKEYS CHEATSHEET                        ║",
    " ╚════════════════════════════════════════════════════════════════════════════════════╝",
    "",
    " 📁 FILE & PROJECT OPERATIONS",
    "   Ctrl + P                 Quick Open file by name (Telescope)",
    "   Ctrl + Shift + P / F1    Command Palette (search all commands & settings)",
    "   Ctrl + Shift + F         Global Find in Files (project-wide ripgrep)",
    "   Ctrl + F                 Find text in current buffer",
    "   Ctrl + Shift + H         Find and Replace across all files (grug-far)",
    "   Ctrl + B / Ctrl + \\      Toggle File Explorer sidebar (neo-tree)",
    "   Ctrl + Shift + E         Focus File Explorer sidebar",
    "   Ctrl + Shift + O         Go to Symbol in File (outline / functions / classes)",
    "   Ctrl + T                 Go to Symbol in Workspace",
    "   Ctrl + S                 Save file (Normal, Insert, Visual)",
    "   Ctrl + W                 Close active editor tab / buffer",
    "   Ctrl + Shift + N         New empty file / buffer",
    "",
    " ✏️ EDITING, MULTI-CURSOR & CLIPBOARD",
    "   Ctrl + D                 Multi-Cursor: Select next matching word (press repeatedly)",
    "   Ctrl + Alt + Down / Up   Add Multi-Cursor directly below / above",
    "   Ctrl + / (Ctrl + _)      Toggle Line / Selection Comment (Normal, Insert, Visual)",
    "   Alt + Up / Down          Move Line / Selection Up / Down (also Alt + k / j)",
    "   Shift + Alt + Down / Up  Duplicate Line / Selection Down / Up",
    "   Ctrl + A                 Select All",
    "   Ctrl + Z                 Undo (Normal and Insert modes)",
    "   Ctrl + Y / Ctrl+Shift+Z  Redo (Normal and Insert modes)",
    "   Ctrl + C                 Copy selection to system clipboard",
    "   Ctrl + X                 Cut selection to system clipboard",
    "   Ctrl + V                 Paste from system clipboard (Normal, Insert, Visual)",
    "   Ctrl + Backspace         Delete word backward (Insert mode)",
    "   s                        Flash Jump (type 2 characters to jump anywhere)",
    "   sa / sd / sr             Surround: Add / Delete / Replace quotes or brackets",
    "",
    " 💡 CODE INTELLIGENCE, LSP & REFACTORING",
    "   F12                      Go to Definition (gd)",
    "   Shift + F12 / Alt + F12  Find All References (gr)",
    "   Ctrl + F12               Go to Implementation (gi)",
    "   F2                       Rename Symbol across entire workspace (<leader>rn)",
    "   Ctrl + . / Alt + Enter   Quick Fix / Code Actions (<leader>ca)",
    "   Shift + Alt + F          Format Document with conform.nvim (<leader>cf)",
    "   Ctrl + Shift + I         Format Document (<leader>cf)",
    "   F8 / Shift + F8          Jump to Next / Previous Problem (Error / Warning)",
    "   Ctrl + K                 Hover Documentation / Type info (K)",
    "   Ctrl + Shift + Space     Parameter & Function Signature Hints",
    "",
    " 🖥️ TERMINAL, PROBLEMS & TABS",
    "   Ctrl + ` / Ctrl + ~      Toggle floating integrated terminal (toggleterm)",
    "   Ctrl + Shift + M         Toggle Problems / Diagnostics drawer (Trouble)",
    "   Ctrl + Tab / C-Shift-Tab Next / Previous editor tab (<Tab> / <Shift-Tab>)",
    "   Alt + 1 .. 9             Jump directly to Tab 1 through 9",
    "   Ctrl + H                 Toggle this Hotkeys Cheatsheet popup",
    "   <Space> (Leader)         Open Which-Key popup menu for all extra actions",
    "",
    " ── Press <Esc>, q, or Ctrl+H to close ────────────────────────────────────────────────",
  }

  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "help"

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
    title = " ⚡ IDE Hotkeys ",
    title_pos = "center",
  }

  win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local close_keys = { "<Esc>", "q", "<C-h>" }
  for _, key in ipairs(close_keys) do
    vim.keymap.set("n", key, function()
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        win = nil
      end
    end, { buffer = buf, silent = true, nowait = true })
  end
end

return M
