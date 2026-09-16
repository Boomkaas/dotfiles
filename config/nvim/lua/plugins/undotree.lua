return {
  "mbbill/undotree",
  lazy = false,
  cmd = "UndotreeToggle",
  keys = {
    { "<C-M-u>", "<cmd>UndotreeToggle<cr>", mode = { "n", "i", "x" }, desc = "Toggle Undotree (Ctrl+Alt+U)" },
    { "<C-S-u>", "<cmd>UndotreeToggle<cr>", mode = { "n", "i", "x" }, desc = "Toggle Undotree (Ctrl+Shift+U)" },
  },
}
