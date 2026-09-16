-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Disable bare H and L from switching buffers to prevent accidental triggers (use Ctrl+Tab / Ctrl+Shift+Tab instead)
pcall(vim.keymap.del, "n", "H")
pcall(vim.keymap.del, "n", "L")
