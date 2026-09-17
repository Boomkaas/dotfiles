return {
  "NakLast/antigravity-cli.nvim",
  cmd = { "Antigravity" },
  keys = {
    {
      "<C-M-a>",
      "<cmd>Antigravity<cr>",
      mode = { "n", "i", "t" },
      desc = "Toggle Antigravity CLI (Ctrl+Alt+A)",
    },
    {
      "<C-M-a>",
      "<cmd>lua require('antigravity').ask_selection()<cr>",
      mode = { "v", "x" },
      desc = "Ask Antigravity CLI about Selection (Ctrl+Alt+A)",
    },
  },
  opts = {
    cmd = vim.fn.executable("agy") == 1 and "agy" or (vim.fn.executable("antigravity") == 1 and "antigravity" or "antigravity-cli"),
    width_ratio = 0.85,
    height_ratio = 0.85,
    border = "rounded",
    style = "float",
  },
  config = function(_, opts)
    require("antigravity").setup(opts)
  end,
}
