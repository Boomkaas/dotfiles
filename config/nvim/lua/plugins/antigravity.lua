return {
  "NakLast/antigravity-cli.nvim",
  lazy = false, -- Load immediately so keymaps are always registered across all modes
  cmd = { "Antigravity" },
  keys = {
    -- Toggle Antigravity Assistant (Normal, Insert, Terminal)
    {
      "<C-M-a>",
      function()
        require("antigravity").toggle()
      end,
      mode = { "n", "i", "t" },
      desc = "Toggle Antigravity CLI (Ctrl+Alt+A)",
    },
    {
      "<C-M-g>",
      function()
        require("antigravity").toggle()
      end,
      mode = { "n", "i", "t" },
      desc = "Toggle Antigravity CLI (Ctrl+Alt+G)",
    },
    {
      "<F4>",
      function()
        require("antigravity").toggle()
      end,
      mode = { "n", "i", "t" },
      desc = "Toggle Antigravity CLI (F4)",
    },
    -- Ask Antigravity about Selection (Visual modes)
    {
      "<C-M-a>",
      function()
        require("antigravity").ask_selection()
      end,
      mode = { "v", "x" },
      desc = "Ask Antigravity CLI about Selection (Ctrl+Alt+A)",
    },
    {
      "<C-M-g>",
      function()
        require("antigravity").ask_selection()
      end,
      mode = { "v", "x" },
      desc = "Ask Antigravity CLI about Selection (Ctrl+Alt+G)",
    },
    {
      "<F4>",
      function()
        require("antigravity").ask_selection()
      end,
      mode = { "v", "x" },
      desc = "Ask Antigravity CLI about Selection (F4)",
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
    local antigravity = require("antigravity")
    antigravity.setup(opts)

    -- Auto-register buffer-local close hotkeys whenever the Antigravity terminal buffer is created
    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("AntigravityTermMaps", { clear = true }),
      pattern = "*",
      callback = function(args)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if bufname:find("antigravity") or bufname:find("agy") then
          -- In terminal mode, allow fast toggle-off with Ctrl+Alt+A, Ctrl+Alt+G, F4, or double-Escape
          local close_fn = function()
            antigravity.toggle()
          end
          local map_opts = { buffer = args.buf, silent = true, noremap = true }
          vim.keymap.set("t", "<C-M-a>", close_fn, vim.tbl_extend("force", map_opts, { desc = "Close Antigravity Floating Terminal" }))
          vim.keymap.set("t", "<C-M-g>", close_fn, vim.tbl_extend("force", map_opts, { desc = "Close Antigravity Floating Terminal" }))
          vim.keymap.set("t", "<F4>", close_fn, vim.tbl_extend("force", map_opts, { desc = "Close Antigravity Floating Terminal" }))
          vim.keymap.set("t", "<Esc><Esc>", close_fn, vim.tbl_extend("force", map_opts, { desc = "Close Antigravity Floating Terminal" }))
        end
      end,
    })
  end,
}
