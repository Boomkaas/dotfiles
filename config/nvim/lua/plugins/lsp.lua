return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      -- Diagnostic styling and signs
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          source = "if_many",
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Mason package manager setup
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      -- Setup capabilities for autocompletion
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if cmp_lsp then
        capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
      end

      -- Attach keybindings on LSP connection
      local on_attach = function(client, bufnr)
        local map = function(mode, keys, func, desc)
          vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end

        map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
        map("n", "gr", vim.lsp.buf.references, "Goto References")
        map("n", "gi", vim.lsp.buf.implementation, "Goto Implementation")
        map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
        map("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
        map("n", "<leader>cf", function()
          require("conform").format({ bufnr = bufnr })
        end, "Format Document")
      end

      -- Servers to automatically install and configure via Mason
      local servers = {
        pyright = {},
        rust_analyzer = {},
        ts_ls = {},
        html = {},
        cssls = {},
        jsonls = {},
        bashls = {},
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.fn.expand("$VIMRUNTIME/lua"),
                  vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
                },
              },
            },
          },
        },
      }

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_installation = true,
        handlers = {
          function(server_name)
            local server_opts = servers[server_name] or {}
            server_opts.capabilities = capabilities
            server_opts.on_attach = on_attach
            require("lspconfig")[server_name].setup(server_opts)
          end,
        },
      })

      -- Also configure Nix language server if available in PATH (nil or nixd)
      if vim.fn.executable("nil") == 1 then
        require("lspconfig").nil_ls.setup({
          capabilities = capabilities,
          on_attach = on_attach,
        })
      elseif vim.fn.executable("nixd") == 1 then
        require("lspconfig").nixd.setup({
          capabilities = capabilities,
          on_attach = on_attach,
        })
      end
    end,
  },
}
