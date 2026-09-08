local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- General augroup
local general_group = augroup("GeneralSettings", { clear = true })

-- Highlight on yank
autocmd("TextYankPost", {
  group = general_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
  desc = "Highlight text on yank",
})

-- Return to last edit position when opening files
autocmd("BufReadPost", {
  group = general_group,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = "Go to last cursor location",
})

-- Auto-resize splits when window is resized
autocmd("VimResized", {
  group = general_group,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
  desc = "Equalize window splits on resize",
})

-- Close certain filetypes easily with 'q'
autocmd("FileType", {
  group = general_group,
  pattern = {
    "qf",
    "help",
    "man",
    "notify",
    "lspinfo",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "checkhealth",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
  desc = "Close with q",
})
