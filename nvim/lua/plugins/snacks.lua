-- snacks.nvim: dashboard, pickers (grep/find), terminal, lazygit, notifications, toggles.

-- Neon nebula gradient; the header colors flow through it while the dashboard is open
local gradient = { "#ff5ef1", "#ff6bd5", "#d36bff", "#9d7bff", "#5ea1ff", "#5ef1ff" }

-- Smooth loop: 8 blended steps between each stop, wrapping back to the start
local ramp = {}
for i = 1, #gradient do
  local a, b = gradient[i], gradient[i % #gradient + 1]
  for s = 0, 7 do ramp[#ramp + 1] = require("config.fx").blend(a, b, s / 8) end
end

local offset = 0
local function set_header_hl()
  for row = 1, 6 do
    vim.api.nvim_set_hl(0, "DashHeader" .. row, { fg = ramp[(offset + (row - 1) * 4) % #ramp + 1], bold = true })
  end
  vim.api.nvim_set_hl(0, "DashSub", { fg = "#ffbd5e", italic = true })
  vim.api.nvim_set_hl(0, "DashStars", { fg = ramp[(offset + 24) % #ramp + 1] })
  vim.api.nvim_set_hl(0, "DashMeta", { fg = "#5c6370", italic = true })
end

-- Shift the gradient every 70ms, only while a dashboard window is on screen
local timer
local function animate_header()
  if timer then return end
  timer = vim.uv.new_timer()
  timer:start(0, 70, vim.schedule_wrap(function()
    local visible = vim.iter(vim.api.nvim_list_wins()):any(function(win)
      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_dashboard"
    end)
    if not visible then
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
      return
    end
    offset = offset + 1
    set_header_hl()
  end))
end

local function greeting()
  local h = tonumber(os.date("%H"))
  return (h < 5 and "Burning the midnight oil" or h < 12 and "Good morning" or h < 17 and "Good afternoon"
    or h < 22 and "Good evening" or "Late-night session") .. ", " .. require("config.user").name()
end

local tips = {
  "<leader>fh replays the trail of files you opened",
  "<leader>bb jumps back to the file you were just in",
  "Files you've opened glow magenta in the file tree",
  "<leader>uS toggles the comet cursor",
  "<leader>ua toggles every animation at once",
  "s flash-jumps anywhere on screen",
  "<leader>rr runs any task in this project",
  "<leader>gc lets Claude write your commit message",
  "Press . on the dashboard to reopen your last file",
  ":SetName changes the name on this screen",
}

local PANE_WIDTH = 60

-- Header lines; on wide screens each one is centered across both columns and split
-- at the column edge, so the logo sits on top and the two columns start together below
local function header(self)
  set_header_hl()
  animate_header()
  local width = self and self._size and self._size.width or vim.o.columns
  local two_panes = width >= PANE_WIDTH * 2
  local name = require("config.user").name()

  local lines = {
    { "✦   ·   ˚   ✧   ·   ✦   ·   ✧   ˚   ·   ✦", "DashStars", 1 },
  }
  -- Big letters spelling your name; names too long for the screen get a spaced-out title instead
  local logo = require("config.banner").lines(name, (two_panes and PANE_WIDTH * 2 or PANE_WIDTH) - 4)
  if logo then
    for row, line in ipairs(logo) do lines[#lines + 1] = { line, "DashHeader" .. row } end
  else
    lines[#lines + 1] = { name:upper():gsub(".", "%0 "), "DashHeader1", 1 }
  end
  lines[#lines + 1] = { "\u{f135}  " .. greeting() .. "  ·  welcome to the world of code  \u{f135}", "DashSub" }
  lines[#lines + 1] = {
    os.date("%A, %d %B  ·  %H:%M") .. "  ·  " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
    "DashMeta",
    2,
  }

  local items = {}
  for _, l in ipairs(lines) do
    local text, hl, padding = l[1], l[2], l[3]
    if two_panes then
      local total = PANE_WIDTH * 2
      local w = vim.fn.strdisplaywidth(text)
      local left_pad = math.max(0, math.floor((total - w) / 2))
      local full = (" "):rep(left_pad) .. text
      local left = vim.fn.strcharpart(full, 0, PANE_WIDTH)
      left = left .. (" "):rep(PANE_WIDTH - vim.fn.strdisplaywidth(left))
      local right = vim.fn.strcharpart(full, vim.fn.strchars(left))
      items[#items + 1] = { pane = 1, text = { { left, hl = hl } }, align = "left", padding = padding }
      items[#items + 1] = { pane = 2, text = { { right ~= "" and right or " ", hl = hl } }, align = "left", padding = padding }
    else
      items[#items + 1] = { text = { { text, hl = hl } }, align = "center", padding = padding }
    end
  end
  return items
end

local function footer()
  return {
    text = { { "\u{f0eb}  Tip: " .. tips[math.random(#tips)], hl = "SnacksDashboardFooter" } },
    align = "center",
    padding = 1,
  }
end

-- Keep caches and temp files out of the history lists
local function no_junk(path) return not (path:find("/%.cache/") or path:find("^/tmp/")) end

-- Reopen the file you were in last time (the cursor goes back to the same line)
local function resume_last()
  for _, f in ipairs(vim.v.oldfiles) do
    if vim.uv.fs_stat(f) and no_junk(f) then return vim.cmd.edit(vim.fn.fnameescape(f)) end
  end
  vim.notify("No previous file found", vim.log.levels.INFO)
end

local function lazygit()
  if vim.fn.executable("lazygit") == 0 then
    return vim.notify("lazygit is not installed (sudo pacman -S lazygit)", vim.log.levels.WARN)
  end
  Snacks.lazygit()
end

return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 900,
    opts = {
      bigfile = { enabled = true }, -- disables heavy features on huge files
      quickfile = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      -- Animation engine shared by scroll, indent guides and the file-enter pulse
      animate = { enabled = true, fps = 120, easing = "outQuad" },
      -- Indent scope guide draws itself in when you move into a new block
      indent = {
        enabled = true,
        animate = { enabled = true, style = "out", easing = "outExpo", duration = { step = 15, total = 300 } },
        scope = { hl = "SnacksIndentScope" },
      },
      -- Smooth scrolling for <C-d>/<C-u>, gg/G, search jumps, mouse wheel
      scroll = {
        enabled = true,
        animate = { duration = { step = 10, total = 220 }, easing = "outCubic" },
        animate_repeat = { delay = 100, duration = { step = 5, total = 60 }, easing = "linear" },
      },
      scope = { enabled = true },
      words = { enabled = true },
      statuscolumn = { enabled = true },
      picker = {
        enabled = true,
        ui_select = true,
        matcher = { frecency = true },
        sources = { files = { hidden = true }, grep = { hidden = true } },
        layout = { preset = "default", layout = { backdrop = 45 } },
        icons = { ui = { selected = "\u{f005} ", unselected = "  " } },
        prompt = " \u{f135}  ",
      },
      terminal = { win = { style = "terminal" } },
      lazygit = { configure = true },
      dashboard = {
        enabled = true,
        width = PANE_WIDTH,
        pane_gap = 0, -- the header is split across both columns, so they must touch
        preset = {
          keys = {
            { icon = "\u{f002} ", key = "f", desc = "Find File", action = ":lua Snacks.picker.smart()" },
            { icon = "\u{f07b} ", key = "e", desc = "File Explorer", action = ":Neotree toggle left" },
            { icon = "\u{f15b} ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = "\u{f422} ", key = "g", desc = "Grep Text", action = ":lua Snacks.picker.grep()" },
            { icon = "\u{f112} ", key = ".", desc = "Reopen Last File", action = resume_last },
            { icon = "\u{f1da} ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
            { icon = "\u{f07c} ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
            { icon = "󰚩 ", key = "a", desc = "Claude Code", action = ":ClaudeCode" },
            { icon = "󰊢 ", key = "G", desc = "Lazygit", action = lazygit },
            { icon = "\u{f1c0} ", key = "d", desc = "Database", action = ":DBUIToggle" },
            { icon = "\u{e348} ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
            { icon = "\u{f013} ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = "\u{f487} ", key = "M", desc = "Mason", action = ":Mason" },
            { icon = "\u{f426} ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        -- Two columns on wide screens (actions | history), stacked on narrow ones
        sections = {
          header,
          { section = "keys", gap = 0, padding = 1 },
          { section = "startup", padding = 1 },
          footer,
          {
            pane = 2,
            icon = "    \u{f1da} ", -- leading spaces: gap from the left column
            title = "Continue where you left off",
            section = "recent_files",
            cwd = true,
            limit = 6,
            indent = 4,
            padding = 1,
            filter = no_junk,
          },
          { pane = 2, icon = "    \u{f017} ", title = "Recent anywhere", section = "recent_files", limit = 5, indent = 4, padding = 1, filter = no_junk },
          { pane = 2, icon = "    \u{f07c} ", title = "Projects", section = "projects", limit = 5, indent = 4, padding = 1, filter = no_junk },
        },
      },
    },
    keys = {
      -- Find
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find git files" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files (project)" },
      { "<leader>fh", function() require("config.fx").pick_trail() end, desc = "File trail (history)" },
      { "<leader>bb", function() require("config.fx").go_prev() end, desc = "Previous file" },
      { "<leader>;", function() Snacks.dashboard() end, desc = "Dashboard" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Config files" },
      -- Grep / search
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep project" },
      { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep project" },
      { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Grep word / selection", mode = { "n", "x" } },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Search buffer lines" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep open buffers" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols" },
      { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace symbols" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help pages" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command history" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumplist" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix list" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo history" },
      { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume last search" },
      { "<leader>s\"", function() Snacks.picker.registers() end, desc = "Registers" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
      { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notification history" },
      -- Git
      { "<leader>gg", lazygit, desc = "Lazygit" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
      { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git log (file)" },
      { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git log (line)" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git stash" },
      { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git branches" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Open in browser", mode = { "n", "x" } },
      -- Terminal
      { "<c-/>", function() Snacks.terminal() end, desc = "Toggle terminal", mode = { "n", "t" } },
      { "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore", mode = { "n", "t" } },
      { "<leader>tt", function() Snacks.terminal() end, desc = "Terminal (bottom)" },
      { "<leader>tf", function() Snacks.terminal(nil, { win = { position = "float" } }) end, desc = "Terminal (float)" },
      { "<leader>tv", function() Snacks.terminal(nil, { win = { position = "right" } }) end, desc = "Terminal (right)" },
      -- Misc
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
      { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename file" },
      { "<leader>z", function() Snacks.zen() end, desc = "Zen mode" },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference" },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference" },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_header_hl })
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("relativenumber", { name = "Relative numbers" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.inlay_hints():map("<leader>uh")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.scroll():map("<leader>uU")
          -- Master switch: smooth scroll, indent animation, file pulse and comet cursor
          Snacks.toggle({
            name = "Animations",
            get = function() return vim.g.snacks_animate ~= false end,
            set = function(on)
              vim.g.snacks_animate = on
              local ok, smear = pcall(require, "smear_cursor")
              if ok then smear.enabled = on end
            end,
          }):map("<leader>ua")
        end,
      })
    end,
  },
}
