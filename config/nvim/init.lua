-- Leader key must be set before lazy.nvim and other plugins are loaded
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load core settings
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
