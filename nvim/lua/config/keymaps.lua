-- Plugin-specific keymaps live next to their plugin spec (lua/plugins/*).
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map({ "n", "i", "x" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Taller window" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Shorter window" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Narrower window" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Wider window" })
map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("x", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("x", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Keep selection when indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Centered search results
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })

-- Leave terminal mode quickly
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Project task runner (npm, cargo, maven, gradle, make, python, go, docker…)
map("n", "<leader>rr", function() require("config.runner").pick() end, { desc = "Run project task" })
map("n", "<leader>rl", function() require("config.runner").rerun() end, { desc = "Rerun last task" })
map("n", "<leader>rf", function() require("config.runner").run_file() end, { desc = "Run current file" })

-- AI commit message (Claude Code CLI)
map("n", "<leader>gc", function() require("config.ai_commit").generate() end, { desc = "AI commit (Claude)" })

-- Fire cursor
map("n", "<leader>uF", function() require("config.fx").toggle_style() end, { desc = "Fire / cosmic cursor" })
