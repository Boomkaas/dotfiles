return {
  "saecki/live-rename.nvim",
  opts = {},
  keys = {
    {
      "<C-F2>",
      function()
        require("live-rename").rename()
      end,
      mode = { "n", "x", "i" },
      desc = "Live Rename (Ctrl+F2)",
    },
    {
      "<C-M-r>",
      function()
        require("live-rename").rename()
      end,
      mode = { "n", "x", "i" },
      desc = "Live Rename (Ctrl+Alt+R)",
    },
  },
}
