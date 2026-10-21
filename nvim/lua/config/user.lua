-- Who is using this config: asked once on first start, saved outside the config
-- (stdpath("data")/user.json) so the config itself stays shareable.
-- Change it any time with :SetName.
local M = {}

local file = vim.fn.stdpath("data") .. "/user.json"
local saved -- cached name, false = not set yet

local function read()
  if saved ~= nil then return saved end
  saved = false
  local f = io.open(file, "r")
  if f then
    local ok, data = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(data) == "table" and type(data.name) == "string" and data.name ~= "" then saved = data.name end
  end
  return saved
end

local function write(name)
  vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
  local f = io.open(file, "w")
  if f then
    f:write(vim.json.encode({ name = name }))
    f:close()
  end
  saved = name
end

--- The user's name; falls back to the login name until they've told us
function M.name()
  local name = read()
  if name then return name end
  local login = vim.env.USER or vim.env.USERNAME or "friend"
  return login:sub(1, 1):upper() .. login:sub(2)
end

local function refresh_dashboard()
  if package.loaded["snacks"] and vim.bo.filetype == "snacks_dashboard" then Snacks.dashboard.update() end
end

--- Ask for the name (prefilled with the current one) and redraw the dashboard
function M.ask()
  vim.ui.input({ prompt = "What's your name? ", default = read() or M.name() }, function(input)
    input = input and vim.trim(input) or ""
    if input == "" then return end
    write(input)
    refresh_dashboard()
    vim.notify("Welcome, " .. input .. "!", vim.log.levels.INFO)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("SetName", function(cmd)
    if cmd.args ~= "" then
      write(vim.trim(cmd.args))
      refresh_dashboard()
    else
      M.ask()
    end
  end, { nargs = "?", desc = "Set the name shown on the dashboard" })

  -- First start: ask once, after the UI (and the input popup) is ready
  if not read() then
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function() vim.defer_fn(M.ask, 200) end,
    })
  end
end

return M
