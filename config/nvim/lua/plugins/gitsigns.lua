return {
  "lewis6991/gitsigns.nvim",
  opts = {
    signcolumn = true,
    numhl = true, -- Highlight line numbers of added/modified/deleted code
    linehl = true, -- Highlight full line backgrounds for added and modified code
    word_diff = true, -- Highlight intra-line word-level differences
    show_deleted = true, -- Display removed/deleted code inline as virtual text
    diff_opts = {
      internal = true,
    },
  },
}
