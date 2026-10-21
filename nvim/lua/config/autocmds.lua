local au = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

au("TextYankPost", {
  group = group,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Reopen files at the last cursor position
au("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Reload files changed outside Neovim (e.g. by Claude Code or git)
au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  callback = function()
    if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
  end,
})

au("VimResized", { group = group, command = "tabdo wincmd =" })

-- Close helper windows with q
au("FileType", {
  group = group,
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "notify", "grug-far", "dap-float" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- Wrap & spellcheck in prose files
au("FileType", {
  group = group,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- 4-space languages
au("FileType", {
  group = group,
  pattern = { "java", "python", "rust", "go" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})
