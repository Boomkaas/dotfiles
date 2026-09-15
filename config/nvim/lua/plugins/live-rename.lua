return {
  "saecki/live-rename.nvim",
  opts = {},
  keys = {
    {
      "<leader>cr",
      function()
        require("live-rename").rename()
      end,
      desc = "Live Rename",
    },
    {
      "r",
      function()
        require("live-rename").rename()
      end,
      mode = "x",
      desc = "Live Rename Selection",
    },
  },
}
