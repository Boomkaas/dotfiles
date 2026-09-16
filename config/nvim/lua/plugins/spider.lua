return {
  "chrisgrieser/nvim-spider",
  event = "VeryLazy",
  opts = {
    skipInsignificantPunctuation = true,
  },
  keys = {
    { "<C-Right>", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x", "i" }, desc = "Spider Word Right (Ctrl+Right)" },
    { "<C-Left>", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x", "i" }, desc = "Spider Word Left (Ctrl+Left)" },
    { "<C-M-Right>", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x", "i" }, desc = "Spider Word End (Ctrl+Alt+Right)" },
    { "<C-M-Left>", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x", "i" }, desc = "Spider Word Prev End (Ctrl+Alt+Left)" },
  },
}
