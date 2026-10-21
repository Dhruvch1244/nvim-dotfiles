-- Visual effects: one "void" palette, mode-aware cursor colors, a light pulse
-- when you land in a file, and a trail of the files you opened before.
local M = {}

-- Deep-space palette shared by the theme, cursor, dashboard and statusline
M.palette = {
  void = "#060709", -- editor background (near black)
  deep = "#0b0d10", -- floats, sidebars
  hull = "#13161b", -- cursorline, selections
  rim = "#252a33", -- borders, separators
  dust = "#5c6370", -- muted text
  cyan = "#5ef1ff",
  blue = "#5ea1ff",
  violet = "#9d7bff",
  purple = "#bd5eff",
  magenta = "#ff5ef1",
  pink = "#ff5ea0",
  green = "#5eff6c",
  orange = "#ffbd5e",
  red = "#ff6e5e",
}
local p = M.palette

-- Mode → accent color (cursor, smear trail, line number, statusline)
M.mode_colors = {
  n = p.cyan,
  i = p.magenta,
  v = p.purple,
  V = p.purple,
  ["\22"] = p.purple, -- visual block
  R = p.red,
  c = p.orange,
  t = p.green,
}

-- Fire style: each mode burns a different flame, hottest → coolest
M.flames = {
  n = { "#fff1a8", "#ffc93c", "#ff8a1f", "#ff4d1a" }, -- classic orange fire
  i = { "#e0f7ff", "#8fdcff", "#3fa0ff", "#2a5bff" }, -- blue flame (hotter: you're typing)
  v = { "#ffd6ff", "#ff7af5", "#c85eff", "#8a3dff" }, -- purple flame
  R = { "#ffd0c0", "#ff7a5e", "#ff3b2e", "#c2141a" }, -- red flame
  c = { "#eaffc8", "#9dff6a", "#3fe85e", "#14a84a" }, -- green flame
  t = { "#eaffc8", "#9dff6a", "#3fe85e", "#14a84a" },
}
M.flames.V, M.flames["\22"] = M.flames.v, M.flames.v

M.style = "fire" -- "fire" or "cosmic"; <leader>uF switches

local function flame(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  return M.flames[mode:sub(1, 1)] or M.flames[mode] or M.flames.n
end

function M.mode_color(mode)
  if M.style == "fire" then return flame(mode)[2] end
  mode = mode or vim.api.nvim_get_mode().mode
  return M.mode_colors[mode:sub(1, 1)] or M.mode_colors[mode] or p.cyan
end

-- Blend two #rrggbb colors; t = 0 → a, t = 1 → b
function M.blend(a, b, t)
  local function ch(hex, i) return tonumber(hex:sub(i, i + 1), 16) end
  local out = "#"
  for _, i in ipairs({ 2, 4, 6 }) do
    out = out .. ("%02x"):format(math.floor(ch(a, i) + (ch(b, i) - ch(a, i)) * t + 0.5))
  end
  return out
end

---------------------------------------------------------------------------
-- Mode-aware cursor: block color, line number glow and smear trail follow the mode
---------------------------------------------------------------------------
local function set_cursor_color(c)
  vim.api.nvim_set_hl(0, "Cursor", { fg = p.void, bg = c })
  vim.api.nvim_set_hl(0, "lCursor", { fg = p.void, bg = c })
  local smear = package.loaded["smear_cursor"]
  if smear then
    smear.cursor_color = c
    smear.cursor_color_insert_mode = c
  end
end

local function paint_mode()
  local c = M.mode_color()
  set_cursor_color(c)
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c, bold = true })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = M.blend(p.void, c, 0.07) })
end
M.paint_mode = paint_mode

---------------------------------------------------------------------------
-- Flicker: while the cursor moves, the trail and embers cycle through the flame
-- colors like real fire; it settles on the base color ~0.6s after you stop
---------------------------------------------------------------------------
local flicker = { timer = vim.uv.new_timer(), running = false, last_move = 0 }
local FLICKER_MS = 55 -- ~18 color changes per second
local SETTLE_MS = 600

local function flicker_tick()
  if vim.uv.now() - flicker.last_move > SETTLE_MS or M.style ~= "fire" then
    flicker.timer:stop()
    flicker.running = false
    paint_mode()
    return
  end
  local f = flame()
  -- Weighted toward the hot middle of the flame, with the odd white-hot or deep flash
  local r = math.random()
  set_cursor_color(r < 0.15 and f[1] or r < 0.6 and f[2] or r < 0.9 and f[3] or f[4])
end

local function on_move()
  if M.style ~= "fire" then return end
  flicker.last_move = vim.uv.now()
  if not flicker.running then
    flicker.running = true
    flicker.timer:start(0, FLICKER_MS, vim.schedule_wrap(flicker_tick))
  end
end

function M.toggle_style()
  M.style = M.style == "fire" and "cosmic" or "fire"
  paint_mode()
  vim.notify(M.style == "fire" and "\u{f06d} Fire cursor" or "\u{f005} Cosmic cursor", vim.log.levels.INFO)
end

---------------------------------------------------------------------------
-- Beacon: the cursor line flashes and fades out when you enter a file
---------------------------------------------------------------------------
local ns = vim.api.nvim_create_namespace("fx_beacon")

function M.beacon(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" or not Snacks then return end
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local id = vim.api.nvim_buf_set_extmark(buf, ns, line, 0, {
    line_hl_group = "FxBeacon",
    priority = 200,
  })
  local from, to = M.mode_color(), p.void
  Snacks.animate(0, 100, function(v, ctx)
    vim.api.nvim_set_hl(0, "FxBeacon", { bg = M.blend(from, to, 0.55 + 0.45 * v / 100) })
    if ctx.done then pcall(vim.api.nvim_buf_del_extmark, buf, ns, id) end
  end, { id = "fx_beacon", duration = { total = 550 }, easing = "outCubic", buf = buf })
end

---------------------------------------------------------------------------
-- File trail: every real file you open, newest first (this session)
---------------------------------------------------------------------------
M.trail = {}

local function remember(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" or not vim.uv.fs_stat(name) then return end
  for i, f in ipairs(M.trail) do
    if f == name then
      table.remove(M.trail, i)
      break
    end
  end
  table.insert(M.trail, 1, name)
  if #M.trail > 50 then M.trail[#M.trail] = nil end
end

-- Statusline breadcrumb: the file you were in before this one
function M.prev_file()
  local prev = M.trail[2]
  if not prev or vim.bo.buftype ~= "" then return "" end
  return "\u{f112} " .. vim.fn.fnamemodify(prev, ":t")
end

function M.go_prev()
  local prev = M.trail[2]
  if not prev then return vim.notify("No previous file yet", vim.log.levels.INFO) end
  vim.cmd.edit(vim.fn.fnameescape(prev))
end

-- Picker over the trail: numbered, newest first, with a live preview
function M.pick_trail()
  local items = {}
  for i, f in ipairs(M.trail) do
    items[#items + 1] = { idx = i, file = f, text = f }
  end
  if #items == 0 then return Snacks.picker.recent({ filter = { cwd = true } }) end
  Snacks.picker.pick({
    title = "\u{f1da}  File trail (this session)",
    items = items,
    format = function(item, picker)
      local ret = { { ("%2d "):format(item.idx), item.idx == 1 and "Special" or "Comment" } }
      vim.list_extend(ret, require("snacks.picker.format").filename(item, picker))
      return ret
    end,
    preview = "file",
  })
end

---------------------------------------------------------------------------
-- Hold mode: while a key auto-repeats (holding j, <C-d>, w…), switch to light
-- effects so nothing stutters, then restore the full show when it's released
---------------------------------------------------------------------------
local hold = { active = false, last_key = nil, last_time = 0, saved = nil }
local HOLD_GAP = 90 -- ms; auto-repeat fires every ~25-50ms, separate taps are slower
local RELEASE_AFTER = 160 -- ms without a repeat = key released

-- Lighter cursor settings used while a key is held
local light_smear = {
  particles_enabled = false,
  stiffness = 0.9,
  trailing_stiffness = 0.7,
  max_length = 6,
}

local release_timer = vim.uv.new_timer()

local function enter_hold()
  hold.active = true
  vim.g.snacks_scroll = false -- held scrolling becomes instant instead of restarting animations
  local ok, smear = pcall(require, "smear_cursor")
  if ok and package.loaded["smear_cursor"] then
    hold.saved = {}
    for k, v in pairs(light_smear) do
      hold.saved[k] = smear[k]
      smear[k] = v
    end
  end
end

local function leave_hold()
  hold.active = false
  vim.g.snacks_scroll = nil
  local ok, smear = pcall(require, "smear_cursor")
  if ok and hold.saved then
    for k, v in pairs(hold.saved) do smear[k] = v end
  end
  hold.saved = nil
end

local function on_key(key)
  if key == "" then return end
  local now = vim.uv.now()
  local repeated = key == hold.last_key and now - hold.last_time < HOLD_GAP
  hold.last_key, hold.last_time = key, now
  if repeated then
    if not hold.active then enter_hold() end
    release_timer:stop()
    release_timer:start(RELEASE_AFTER, 0, vim.schedule_wrap(function()
      if hold.active then leave_hold() end
    end))
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_fx", { clear = true })
  local au = vim.api.nvim_create_autocmd

  vim.on_key(on_key, vim.api.nvim_create_namespace("fx_hold"))
  au({ "CursorMoved", "CursorMovedI", "WinScrolled" }, { group = group, callback = on_move })

  au({ "ModeChanged", "ColorScheme", "VimEnter" }, { group = group, callback = paint_mode })
  au("User", { group = group, pattern = "VeryLazy", callback = paint_mode })

  au("BufEnter", {
    group = group,
    callback = function(ev)
      remember(ev.buf)
      -- Wait one tick so the cursor is restored to the last position first
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() == ev.buf then M.beacon(ev.buf) end
      end)
    end,
  })

  -- Blinking, mode-shaped cursor that picks up the colors above
  vim.opt.guicursor = table.concat({
    "n-c:block-Cursor",
    "v:block-Cursor",
    "i-ci-ve:ver25-Cursor-blinkwait300-blinkon250-blinkoff200",
    "r-cr-o:hor20-Cursor",
    "t:block-blinkon500-blinkoff500-TermCursor",
  }, ",")
end

return M
