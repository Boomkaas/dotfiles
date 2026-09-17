return {
  -- Supermaven: Fast AI Code Autocompletion
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    cmd = {
      "SupermavenUseFree",
      "SupermavenUsePro",
      "SupermavenStatus",
      "SupermavenToggle",
      "SupermavenLogout",
      "SupermavenShowLog",
      "SupermavenClearLog",
    },
    opts = {
      keymaps = {
        accept_suggestion = nil, -- Handled cooperatively with blink.cmp via LazyVim ai_accept
        clear_suggestion = "<C-]>",
        accept_word = "<C-M-Right>",
      },
      ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
      color = {
        suggestion_color = "#6c7086",
        cterm = 244,
      },
      log_level = "warn",
      disable_inline_completion = false,
    },
    config = function(_, opts)
      require("supermaven-nvim").setup(opts)
      require("supermaven-nvim.completion_preview").suggestion_group = "SupermavenSuggestion"
      LazyVim.cmp.actions.ai_accept = function()
        local suggestion = require("supermaven-nvim.completion_preview")
        if suggestion.has_suggestion() then
          LazyVim.create_undo()
          vim.schedule(function()
            suggestion.on_accept_suggestion()
          end)
          return true
        end
      end
    end,
  },

  -- Blink.cmp: Next-generation fast autocomplete engine with LSP, fuzzy search, and signature help
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 150,
          window = {
            border = "rounded",
          },
        },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
          },
        },
        ghost_text = {
          enabled = vim.g.ai_cmp, -- If AI is in cmp menu, show ghost text; otherwise Supermaven handles inline ghost text
        },
      },
      signature = {
        enabled = true,
        window = {
          border = "rounded",
        },
      },
      keymap = {
        preset = "enter",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = {
          LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" }),
          "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
    },
  },

  -- Clean notification handling for Supermaven
  {
    "folke/noice.nvim",
    optional = true,
    opts = function(_, opts)
      opts.routes = opts.routes or {}
      vim.list_extend(opts.routes, {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "Starting Supermaven" },
              { find = "Supermaven Free Tier" },
            },
          },
          skip = true,
        },
      })
    end,
  },
}
