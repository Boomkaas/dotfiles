return {
  -- Total Black (OLED Pure Black #000000) Theme Configuration
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      styles = {
        sidebars = "dark",
        floats = "dark",
      },
      on_colors = function(colors)
        -- Set all background surfaces to total pitch black #000000
        colors.bg = "#000000"
        colors.bg_dark = "#000000"
        colors.bg_float = "#000000"
        colors.bg_sidebar = "#000000"
        colors.bg_statusline = "#000000"
        colors.bg_popup = "#050505"
        colors.border = "#202024"
        colors.border_highlight = "#3a3a44"
        colors.fg_gutter = "#3a3a44"
      end,
      on_highlights = function(hl, colors)
        -- Core Editor Surfaces
        hl.Normal = { bg = "#000000", fg = colors.fg }
        hl.NormalNC = { bg = "#000000", fg = colors.fg_dark }
        hl.NormalFloat = { bg = "#000000", fg = colors.fg_float }
        hl.FloatBorder = { bg = "#000000", fg = "#333338" }
        hl.FloatTitle = { bg = "#000000", fg = colors.blue, bold = true }
        hl.SignColumn = { bg = "#000000" }
        hl.LineNr = { bg = "#000000", fg = "#444450" }
        hl.CursorLineNr = { bg = "#000000", fg = "#c0caf5", bold = true }
        hl.CursorLine = { bg = "#0c0c0f" }
        hl.FoldColumn = { bg = "#000000" }
        hl.EndOfBuffer = { bg = "#000000", fg = "#000000" }

        -- Windows, Separators & Splits
        hl.WinSeparator = { fg = "#202024", bg = "#000000" }
        hl.VertSplit = { fg = "#202024", bg = "#000000" }
        hl.StatusLine = { bg = "#000000" }
        hl.StatusLineNC = { bg = "#000000" }
        hl.TabLine = { bg = "#000000" }
        hl.TabLineFill = { bg = "#000000" }
        hl.TabLineSel = { bg = "#000000" }

        -- BufferLine (Tabs)
        hl.BufferLineFill = { bg = "#000000" }
        hl.BufferLineBackground = { bg = "#000000" }
        hl.BufferLineBufferSelected = { bg = "#000000", bold = true }
        hl.BufferLineSeparator = { fg = "#000000", bg = "#000000" }
        hl.BufferLineSeparatorSelected = { fg = "#000000", bg = "#000000" }

        -- Popup Menus (Autocomplete, etc.)
        hl.Pmenu = { bg = "#070709", fg = colors.fg }
        hl.PmenuSel = { bg = "#202028" }
        hl.PmenuBorder = { bg = "#070709", fg = "#333338" }

        -- Pickers & Panels (Snacks, Telescope, Trouble, Explorer)
        hl.SnacksNormal = { bg = "#000000" }
        hl.SnacksPicker = { bg = "#000000" }
        hl.SnacksPickerBorder = { bg = "#000000", fg = "#333338" }
        hl.SnacksPickerInput = { bg = "#000000" }
        hl.SnacksPickerInputBorder = { bg = "#000000", fg = "#333338" }
        hl.SnacksDashboardNormal = { bg = "#000000" }
        hl.TelescopeNormal = { bg = "#000000" }
        hl.TelescopeBorder = { bg = "#000000", fg = "#333338" }
        hl.TelescopePromptNormal = { bg = "#000000" }
        hl.TelescopePromptBorder = { bg = "#000000", fg = "#333338" }
        hl.TelescopeResultsNormal = { bg = "#000000" }
        hl.TelescopeResultsBorder = { bg = "#000000", fg = "#333338" }
        hl.TelescopePreviewNormal = { bg = "#000000" }
        hl.TelescopePreviewBorder = { bg = "#000000", fg = "#333338" }
        hl.NeoTreeNormal = { bg = "#000000" }
        hl.NeoTreeNormalNC = { bg = "#000000" }
        hl.TroubleNormal = { bg = "#000000" }
        hl.WhichKeyNormal = { bg = "#000000" }
        hl.LazyNormal = { bg = "#000000" }
        hl.MasonNormal = { bg = "#000000" }
        hl.LspInfoBorder = { bg = "#000000", fg = "#333338" }

        -- Glance LSP Preview
        hl.GlanceBorder = { bg = "#000000", fg = "#333338" }
        hl.GlanceListNormal = { bg = "#000000" }
        hl.GlancePreviewNormal = { bg = "#000000" }
      end,
    },
  },

  -- Catppuccin OLED Black Alternative Preset
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      transparent_background = false,
      color_overrides = {
        mocha = {
          base = "#000000",
          mantle = "#000000",
          crust = "#000000",
        },
      },
    },
  },

  -- Configure LazyVim to default to the Total Black theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
