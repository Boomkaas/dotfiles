-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Disable bare H and L from switching buffers to prevent accidental triggers (use Ctrl+Tab / Ctrl+Shift+Tab instead)
pcall(vim.keymap.del, "n", "H")
pcall(vim.keymap.del, "n", "L")

-- =============================================================================
-- Git Keymaps (<leader>g / <space>g)
-- =============================================================================
local map = vim.keymap.set
local function git_root()
  return (LazyVim and LazyVim.root and LazyVim.root.git) and LazyVim.root.git() or vim.uv.cwd()
end

-- Register Which-Key groups for Git
pcall(function()
  local wk = require("which-key")
  wk.add({
    { "<leader>g", group = "git", icon = { icon = "󰊢 ", color = "red" } },
    { "<leader>gh", group = "hunks", icon = { icon = " ", color = "azure" } },
    { "<leader>gH", group = "github", icon = { icon = " ", color = "purple" } },
  })
end)

-- Lazygit (Terminal UI)
if vim.fn.executable("lazygit") == 1 then
  map("n", "<leader>gg", function() Snacks.lazygit({ cwd = git_root() }) end, { desc = "Lazygit (Root Dir)" })
  map("n", "<leader>gG", function() Snacks.lazygit() end, { desc = "Lazygit (cwd)" })
end

-- Status & Diffs
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Git Status" })
map("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "Git Diff (Hunks)" })
map("n", "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, { desc = "Git Diff (Origin)" })
map("n", "<leader>gS", function() Snacks.picker.git_stash() end, { desc = "Git Stash List" })

-- Branches & Checkout
map("n", "<leader>gb", function() Snacks.picker.git_branches() end, { desc = "Git Branches" })

-- Commits & Logs
map("n", "<leader>gc", function() Snacks.picker.git_log({ cwd = git_root() }) end, { desc = "Git Commits (Log)" })
map("n", "<leader>gC", function() Snacks.terminal({ "git", "commit" }, { cwd = git_root() }) end, { desc = "Git Commit (Terminal)" })
map("n", "<leader>gl", function() Snacks.picker.git_log({ cwd = git_root() }) end, { desc = "Git Log (Root)" })
map("n", "<leader>gL", function() Snacks.picker.git_log_line() end, { desc = "Git Log Line" })
map("n", "<leader>gf", function() Snacks.picker.git_log_file() end, { desc = "Git Current File History" })

-- Direct Actions (Push, Pull, Fetch, Stage)
map("n", "<leader>gp", function() Snacks.terminal({ "git", "push" }, { cwd = git_root() }) end, { desc = "Git Push" })
map("n", "<leader>gP", function() Snacks.terminal({ "git", "pull" }, { cwd = git_root() }) end, { desc = "Git Pull" })
map("n", "<leader>gF", function() Snacks.terminal({ "git", "fetch", "--all", "--prune" }, { cwd = git_root() }) end, { desc = "Git Fetch (All)" })
map("n", "<leader>ga", function() require("gitsigns").stage_buffer() end, { desc = "Git Add (Stage Buffer)" })

-- Blame & Inspection
map("n", "<leader>gB", function() require("gitsigns").blame_line({ full = true }) end, { desc = "Git Blame Line (Popup)" })
map("n", "<leader>gt", function() require("gitsigns").toggle_current_line_blame() end, { desc = "Git Toggle Line Blame" })

-- Remote Browsing
map({ "n", "x" }, "<leader>go", function() Snacks.gitbrowse() end, { desc = "Git Browse (Open)" })
map({ "n", "x" }, "<leader>gy", function()
  Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
end, { desc = "Git Browse (Copy URL)" })

-- Hunks (<leader>gh)
map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", { desc = "Stage Hunk" })
map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", { desc = "Reset Hunk" })
map("n", "<leader>ghS", function() require("gitsigns").stage_buffer() end, { desc = "Stage Buffer" })
map("n", "<leader>ghu", function() require("gitsigns").undo_stage_hunk() end, { desc = "Undo Stage Hunk" })
map("n", "<leader>ghR", function() require("gitsigns").reset_buffer() end, { desc = "Reset Buffer" })
map("n", "<leader>ghp", function() require("gitsigns").preview_hunk_inline() end, { desc = "Preview Hunk Inline" })
map("n", "<leader>ghP", function() require("gitsigns").preview_hunk() end, { desc = "Preview Hunk (Popup)" })
map("n", "<leader>ghb", function() require("gitsigns").blame_line({ full = true }) end, { desc = "Blame Line" })
map("n", "<leader>ghB", function() require("gitsigns").blame() end, { desc = "Blame Buffer" })
map("n", "<leader>ghd", function() require("gitsigns").diffthis() end, { desc = "Diff This Buffer" })
map("n", "<leader>ghD", function() require("gitsigns").diffthis("~") end, { desc = "Diff This ~" })

-- GitHub (<leader>gH & fast issues)
map("n", "<leader>gi", function() Snacks.picker.gh_issue() end, { desc = "GitHub Issues (Open)" })
map("n", "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, { desc = "GitHub Issues (All)" })
map("n", "<leader>gHp", function() Snacks.picker.gh_pr() end, { desc = "GitHub PRs (Open)" })
map("n", "<leader>gHP", function() Snacks.picker.gh_pr({ state = "all" }) end, { desc = "GitHub PRs (All)" })
map("n", "<leader>gHi", function() Snacks.picker.gh_issue() end, { desc = "GitHub Issues (Open)" })
map("n", "<leader>gHI", function() Snacks.picker.gh_issue({ state = "all" }) end, { desc = "GitHub Issues (All)" })
