return {
  "NakLast/antigravity-cli.nvim",
  lazy = false, -- Load immediately so keymaps are registered across all modes
  cmd = { "Antigravity" },
  keys = {
    -- Dedicated Toggle (Ctrl+Alt+A across Normal, Insert, Terminal)
    {
      "<C-M-a>",
      function()
        require("antigravity").toggle()
      end,
      mode = { "n", "i", "t" },
      desc = "Toggle Antigravity CLI (Ctrl+Alt+A)",
    },
    -- Dedicated Ask Selection (Ctrl+Alt+A in Visual / Selection mode)
    {
      "<C-M-a>",
      function()
        require("antigravity").ask_selection()
      end,
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
    local antigravity = require("antigravity")
    antigravity.setup(opts)

    -- Intercept toggle to auto-sync file changes on disk and refresh diff highlights
    local orig_toggle = antigravity.toggle
    antigravity.toggle = function()
      orig_toggle()
      vim.schedule(function()
        vim.cmd("checktime")
        pcall(function()
          require("gitsigns").refresh()
        end)
      end)
    end

    -- Dedicated buffer-local bindings inside the Antigravity floating terminal:
    -- Only Ctrl+Alt+A and EscEsc are dedicated to closing the window.
    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("AntigravityTermMaps", { clear = true }),
      pattern = "*",
      callback = function(args)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if bufname:find("antigravity") or bufname:find("agy") then
          local close_fn = function()
            antigravity.toggle()
          end
          local map_opts = { buffer = args.buf, silent = true, noremap = true }
          vim.keymap.set("t", "<C-M-a>", close_fn, vim.tbl_extend("force", map_opts, { desc = "Close Antigravity Floating Terminal (Ctrl+Alt+A)" }))
          vim.keymap.set("t", "<Esc><Esc>", close_fn, vim.tbl_extend("force", map_opts, { desc = "Close Antigravity Floating Terminal (EscEsc)" }))
        end
      end,
    })

    -- Auto-reload buffers and update added/removed code highlights whenever focus returns to an editor buffer
    vim.api.nvim_create_autocmd({ "FocusGained", "TermLeave", "BufEnter" }, {
      group = vim.api.nvim_create_augroup("AntigravityFileSync", { clear = true }),
      callback = function()
        if vim.bo.buftype == "" and vim.bo.buflisted then
          vim.cmd("checktime")
          pcall(function()
            require("gitsigns").refresh()
          end)
        end
      end,
    })
  end,
}
