-- Generate a commit message for the staged diff with `claude -p`,
-- show it in an editable float, and commit on <CR>.
local M = {}

local PROMPT = table.concat({
  "Write a git commit message for the staged diff on stdin.",
  "Use Conventional Commits: a subject line of at most 72 characters,",
  "then a blank line and a short body explaining what changed and why (omit the body for trivial changes).",
  "Output ONLY the commit message: no code fences, no commentary.",
}, " ")

local function open(msg)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(msg, "\n"))
  vim.bo[buf].filetype = "gitcommit"

  local width = math.min(90, vim.o.columns - 4)
  local height = math.min(math.max(#vim.split(msg, "\n") + 2, 8), vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " 󰊢 AI commit · <CR> commit · q cancel ",
    title_pos = "center",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<CR>", function()
    local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    close()
    local res = vim.system({ "git", "commit", "-F", "-" }, { stdin = text, text = true }):wait()
    if res.code == 0 then
      vim.notify(vim.split(res.stdout, "\n")[1], vim.log.levels.INFO, { title = "Committed" })
    else
      vim.notify(res.stderr ~= "" and res.stderr or res.stdout, vim.log.levels.ERROR, { title = "git commit" })
    end
  end, { buffer = buf })
end

function M.generate()
  if vim.fn.executable("claude") == 0 then
    return vim.notify("`claude` CLI not found in PATH", vim.log.levels.ERROR)
  end
  local diff = vim.system({ "git", "diff", "--cached", "--no-color" }, { text = true }):wait()
  if diff.code ~= 0 then
    return vim.notify("Not inside a git repository", vim.log.levels.WARN)
  end
  if vim.trim(diff.stdout) == "" then
    return vim.notify("Nothing staged. Stage hunks with <leader>hs or in lazygit.", vim.log.levels.WARN)
  end

  local input = diff.stdout
  if #input > 80000 then input = input:sub(1, 80000) .. "\n...[diff truncated]" end

  vim.notify("Claude is writing your commit message…", vim.log.levels.INFO, { title = "AI commit" })
  vim.system({ "claude", "-p", PROMPT }, { stdin = input, text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      return vim.notify(res.stderr, vim.log.levels.ERROR, { title = "claude" })
    end
    local msg = vim.trim(res.stdout):gsub("^```%w*\n", ""):gsub("\n```$", "")
    open(msg)
  end))
end

return M
