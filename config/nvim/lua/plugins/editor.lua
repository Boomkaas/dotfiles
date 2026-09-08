return {
  -- Neo-tree (File explorer sidebar)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle File Explorer" },
      { "<leader>o", "<cmd>Neotree focus<CR>", desc = "Focus File Explorer" },
      { "<C-b>", "<cmd>Neotree toggle<CR>", desc = "Toggle File Explorer (IDE)" },
      { "<C-\\>", "<cmd>Neotree toggle<CR>", desc = "Toggle File Explorer (IDE)" },
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        use_libuv_file_watcher = true,
      },
      window = {
        width = 30,
        mappings = {
          ["<space>"] = "none",
          ["l"] = "open",
          ["h"] = "close_node",
        },
      },
    },
  },

  -- Telescope (Fuzzy Finder & Command Palette)
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Find Keymaps" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Find Diagnostics" },
      { "<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      -- Standard IDE Shortcuts
      { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Quick Open File (IDE)" },
      { "<C-S-p>", "<cmd>Telescope commands<CR>", desc = "Command Palette (IDE)" },
      { "<F1>", "<cmd>Telescope commands<CR>", desc = "Command Palette (IDE)" },
      { "<C-S-f>", "<cmd>Telescope live_grep<CR>", desc = "Find in Files (IDE)" },
      { "<C-f>", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Find in Buffer (IDE)" },
      { "<C-S-o>", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Go to Symbol in File (IDE)" },
      { "<C-t>", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Go to Symbol in Workspace (IDE)" },
      { "<C-h>", "<cmd>Telescope keymaps<CR>", desc = "List All Hotkeys (IDE)" },
    },
    opts = {
      defaults = {
        prompt_prefix = "   ",
        selection_caret = "  ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- ToggleTerm (Integrated Terminal - Ctrl+` / Ctrl+~)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<C-`>", "<cmd>ToggleTerm direction=float<CR>", desc = "Toggle Terminal (Float)" },
      { "<C-~>", "<cmd>ToggleTerm direction=float<CR>", desc = "Toggle Terminal (Float)" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Float Terminal" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal size=15<CR>", desc = "Horizontal Terminal" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=60<CR>", desc = "Vertical Terminal" },
    },
    opts = {
      open_mapping = [[<C-`>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float",
      close_on_exit = true,
      float_opts = {
        border = "curved",
        winblend = 0,
      },
    },
  },

  -- Trouble (Problems / Diagnostics Drawer - Ctrl+Shift+M)
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Trouble" },
    keys = {
      { "<C-S-m>", "<cmd>Trouble diagnostics toggle<CR>", desc = "Toggle Problems Panel (IDE)" },
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP Definitions / references / ... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<CR>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix List (Trouble)" },
    },
    opts = {},
  },

  -- Grug-Far (Project-Wide Find & Replace - Ctrl+Shift+H)
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      { "<C-S-h>", "<cmd>GrugFar<CR>", desc = "Find and Replace (IDE)" },
      { "<leader>sr", "<cmd>GrugFar<CR>", desc = "Search & Replace (GrugFar)" },
    },
    opts = { headerMaxWidth = 80 },
  },

  -- Multi-Cursor support (VS Code style Ctrl+D / Ctrl+Alt+Up / Down)
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select All"] = "<C-M-d>",
        ["Add Cursor Down"] = "<C-M-Down>",
        ["Add Cursor Up"] = "<C-M-Up>",
      }
    end,
  },

  -- Flash (Lightning fast jump navigation)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- Mini.pairs (Auto-closing parentheses, brackets, quotes)
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {},
  },

  -- Mini.surround (Add/change/delete surrounding delimiter pairs)
  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "sa",            -- Add surrounding in Normal and Visual modes
        delete = "sd",         -- Delete surrounding
        find = "sf",           -- Find surrounding (to the right)
        find_left = "sF",      -- Find surrounding (to the left)
        highlight = "sh",      -- Highlight surrounding
        replace = "sr",        -- Replace surrounding
        update_n_lines = "sn", -- Update `n_lines`
      },
    },
  },

  -- Mini.comment (Fast comment toggling)
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {},
  },
}
