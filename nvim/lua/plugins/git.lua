return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },
      current_line_blame_formatter = "  \u{f417} <author>, <author_time:%R> · <summary>",
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = buf, desc = desc }) end
        map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
        map({ "n", "x" }, "<leader>hs", ":Gitsigns stage_hunk<cr>", "Stage hunk")
        map({ "n", "x" }, "<leader>hr", ":Gitsigns reset_hunk<cr>", "Reset hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>hB", gs.blame, "Blame file")
        map("n", "<leader>hd", gs.diffthis, "Diff this")
        map("n", "<leader>ub", gs.toggle_current_line_blame, "Toggle inline blame")
        map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<cr>", "Select hunk")
      end,
    },
  },

  -- Side-by-side diffs, merge-conflict resolution, file history
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view (working tree)" },
      { "<leader>gD", "<cmd>DiffviewOpen origin/HEAD...HEAD<cr>", desc = "Diff view (branch vs origin)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
    },
    opts = { enhanced_diff_hl = true },
  },
}
