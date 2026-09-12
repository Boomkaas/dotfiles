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
    " ║                          ⚡ VS CODE HOTKEYS CHEATSHEET                              ║",
    " ╚════════════════════════════════════════════════════════════════════════════════════╝",
    "",
    " 📁 FILE & PROJECT OPERATIONS",
    "   Ctrl + P                 Quick Open file by name (Telescope)",
    "   Ctrl + Shift + P / F1    Command Palette (search all commands & settings)",
    "   Ctrl + S / Ctrl+Shift+S  Save file / Save file As",
    "   Ctrl + W / Ctrl+K W      Close active editor tab / Close all editor tabs",
    "   Ctrl + N                 New empty file / buffer",
    "   Ctrl + B / Ctrl + \\      Toggle File Explorer / Split Editor Vertically",
    "   Ctrl + Shift + E         Focus File Explorer sidebar",
    "   Ctrl + Shift + O         Go to Symbol in File (outline / functions / classes)",
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
    "   F2                       Rename Symbol across entire workspace",
    "   Ctrl + . / Alt + Enter   Quick Fix / Code Actions",
    "   Shift + Alt + F          Format Document (conform.nvim)",
    "   Ctrl + Shift + I         Format Document (conform.nvim)",
    "   F8 / Shift + F8          Jump to Next / Previous Problem (Error / Warning)",
    "   Ctrl + K / Ctrl + K C-I  Hover Documentation / Type info",
    "   Ctrl + Space             Trigger suggestions / autocompletion",
    "   Ctrl + Shift + Space     Parameter & Function Signature Hints",
    "",
    " 🖥️ TERMINAL, PROBLEMS & MULTI-CURSOR",
    "   Ctrl + ` / Ctrl + ~      Toggle floating integrated terminal (toggleterm)",
    "   Ctrl + Shift + M         Toggle Problems / Diagnostics drawer (Trouble)",
    "   Ctrl + D                 Multi-Cursor: Select next matching word",
    "   Ctrl + Shift + L         Multi-Cursor: Select all matching occurrences",
    "   Ctrl + Tab / C-Shift-Tab Next / Previous editor tab",
    "   Alt + 1 .. 9             Jump directly to Tab 1 through 9",
    "   Alt + Left / Alt + Right Navigate Back / Forward in history",
    "   Ctrl + K Ctrl + S        Toggle this VS Code Hotkeys Cheatsheet",
    "   <Space> (Leader)         Open Which-Key popup menu for all extra actions",
    "",
    " ── Press <Esc> or q to close ─────────────────────────────────────────────────────────",
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
    title = " ⚡ VS Code Hotkeys ",
    title_pos = "center",
  }

  win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local close_keys = { "<Esc>", "q" }
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
