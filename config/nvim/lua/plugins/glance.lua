return {
  "dnlhc/glance.nvim",
  cmd = "Glance",
  keys = {
    { "<C-M-d>", "<cmd>Glance definitions<cr>", mode = { "n", "i" }, desc = "Glance Definitions (Ctrl+Alt+D)" },
    { "<C-M-r>", "<cmd>Glance references<cr>", mode = { "n", "i" }, desc = "Glance References (Ctrl+Alt+R)" },
    { "<C-M-y>", "<cmd>Glance type_definitions<cr>", mode = { "n", "i" }, desc = "Glance Type Definitions (Ctrl+Alt+Y)" },
    { "<C-M-i>", "<cmd>Glance implementations<cr>", mode = { "n", "i" }, desc = "Glance Implementations (Ctrl+Alt+I)" },
    { "<M-F12>", "<cmd>Glance definitions<cr>", mode = { "n", "i" }, desc = "Peek Definition (Alt+F12)" },
  },
  opts = {},
}
