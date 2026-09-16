return {
  "folke/flash.nvim",
  keys = {
    -- Disable accidental bare letter trigger on 's' and 'S'
    { "s", mode = { "n", "x", "o" }, false },
    { "S", mode = { "n", "x", "o" }, false },
    -- Move to safe Ctrl/Alt shortcuts
    {
      "<C-M-s>",
      mode = { "n", "x", "o", "i" },
      function()
        require("flash").jump()
      end,
      desc = "Flash Jump (Ctrl+Alt+S)",
    },
    {
      "<C-M-S>",
      mode = { "n", "x", "o", "i" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter (Ctrl+Alt+Shift+S)",
    },
  },
}
