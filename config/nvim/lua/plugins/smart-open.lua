return {
  "danielfalk/smart-open.nvim",
  branch = "0.2.x",
  event = "VeryLazy",
  dependencies = {
    "kkharji/sqlite.lua",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  init = function()
    if not vim.g.sqlite_clib_path then
      local paths = vim.fn.glob("/nix/store/*-sqlite-*/lib/libsqlite3.so", false, true)
      if #paths > 0 then
        vim.g.sqlite_clib_path = paths[#paths]
      end
    end
  end,
  config = function()
    pcall(function()
      require("telescope").load_extension("smart_open")
    end)
  end,
  keys = {
    {
      "<C-p>",
      function()
        require("telescope").extensions.smart_open.smart_open()
      end,
      mode = { "n", "i", "v" },
      desc = "Smart Open (Ctrl+P)",
    },
    {
      "<C-o>",
      function()
        require("telescope").extensions.smart_open.smart_open()
      end,
      mode = { "n", "i", "v" },
      desc = "Smart Open (Ctrl+O)",
    },
    {
      "<C-Space>",
      function()
        require("telescope").extensions.smart_open.smart_open()
      end,
      mode = { "n", "i", "v" },
      desc = "Smart Open (Ctrl+Space)",
    },
  },
}
