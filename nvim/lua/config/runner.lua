-- Project script detector & runner.
-- Finds runnable tasks for the project around the current file (npm/pnpm/yarn/bun,
-- Cargo, Maven, Gradle, Make, just, Python/uv/poetry/Django, Go, Deno, Docker Compose)
-- and runs the chosen one in a terminal split.
local M = {}

local last -- last task that ran, for rerun

local function exists(path) return vim.uv.fs_stat(path) ~= nil end

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function start_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.bo.buftype == "" then return vim.fs.dirname(name) end
  return vim.fn.getcwd()
end

local function root(markers) return vim.fs.root(start_dir(), markers) end

-- Each detector returns a list of { label, cmd, cwd, kind }
local detectors = {}

function detectors.node()
  local dir = root({ "package.json" })
  if not dir then return {} end
  local ok, pkg = pcall(vim.json.decode, read(dir .. "/package.json") or "")
  if not ok or type(pkg) ~= "table" then return {} end

  -- Lockfiles live at the workspace root, which may be above the nearest package.json
  local function lock(file) return vim.fs.root(dir, { file }) ~= nil end
  local pm = (lock("bun.lockb") or lock("bun.lock")) and "bun"
    or lock("pnpm-lock.yaml") and "pnpm"
    or lock("yarn.lock") and "yarn"
    or "npm"

  local items = {}
  local names = vim.tbl_keys(pkg.scripts or {})
  -- Most used scripts first, the rest alphabetically
  local prio = { dev = 1, start = 2, build = 3, test = 4, lint = 5, serve = 6, watch = 7 }
  table.sort(names, function(a, b)
    local pa, pb = prio[a] or 99, prio[b] or 99
    if pa ~= pb then return pa < pb end
    return a < b
  end)
  for _, name in ipairs(names) do
    items[#items + 1] = {
      label = name,
      detail = pkg.scripts[name],
      cmd = pm .. " run " .. name,
      cwd = dir,
      kind = pm,
    }
  end
  items[#items + 1] = { label = "install", cmd = pm .. " install", cwd = dir, kind = pm }
  if exists(dir .. "/angular.json") then
    items[#items + 1] = { label = "ng generate component", cmd = "npx ng generate component ", cwd = dir, kind = "angular", edit = true }
  end
  return items
end

function detectors.deno()
  local dir = root({ "deno.json", "deno.jsonc" })
  if not dir then return {} end
  local file = exists(dir .. "/deno.json") and "/deno.json" or "/deno.jsonc"
  local ok, cfg = pcall(vim.json.decode, read(dir .. file) or "")
  local items = {}
  for name, cmd in pairs(ok and cfg.tasks or {}) do
    items[#items + 1] = { label = name, detail = type(cmd) == "string" and cmd or nil, cmd = "deno task " .. name, cwd = dir, kind = "deno" }
  end
  return items
end

function detectors.cargo()
  local dir = root({ "Cargo.toml" })
  if not dir then return {} end
  local items = {}
  for _, c in ipairs({
    "run", "build", "test", "check", "clippy", "fmt", "run --release", "build --release", "doc --open", "update",
  }) do
    items[#items + 1] = { label = c, cmd = "cargo " .. c, cwd = dir, kind = "cargo" }
  end
  return items
end

function detectors.maven()
  local dir = root({ "pom.xml" })
  if not dir then return {} end
  local mvn = exists(dir .. "/mvnw") and "./mvnw" or "mvn"
  local pom = read(dir .. "/pom.xml") or ""
  local goals = { "clean install", "compile", "test", "package", "clean", "verify", "dependency:tree", "-DskipTests package" }
  if pom:find("spring%-boot") then table.insert(goals, 1, "spring-boot:run") end
  if pom:find("quarkus") then table.insert(goals, 1, "quarkus:dev") end
  local items = {}
  for _, g in ipairs(goals) do
    items[#items + 1] = { label = g, cmd = mvn .. " " .. g, cwd = dir, kind = "maven" }
  end
  return items
end

function detectors.gradle()
  local dir = root({ "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" })
  if not dir then return {} end
  local gradle = exists(dir .. "/gradlew") and "./gradlew" or "gradle"
  local build = (read(dir .. "/build.gradle") or "") .. (read(dir .. "/build.gradle.kts") or "")
  local tasks = { "build", "test", "clean", "assemble", "check", "dependencies", "tasks" }
  if build:find("application") then table.insert(tasks, 1, "run") end
  if build:find("spring%-boot") or build:find("org%.springframework%.boot") then table.insert(tasks, 1, "bootRun") end
  if build:find("com%.android") then
    table.insert(tasks, 1, "installDebug")
    table.insert(tasks, 2, "assembleDebug")
  end
  local items = {}
  for _, t in ipairs(tasks) do
    items[#items + 1] = { label = t, cmd = gradle .. " " .. t, cwd = dir, kind = "gradle" }
  end
  return items
end

function detectors.make()
  local dir = root({ "Makefile", "makefile", "GNUmakefile" })
  if not dir then return {} end
  local text = read(dir .. "/Makefile") or read(dir .. "/makefile") or read(dir .. "/GNUmakefile") or ""
  local items, seen = {}, {}
  for target in ("\n" .. text):gmatch("\n([%w_][%w_%-%./]*)%s*:[^=]") do
    if not seen[target] then
      seen[target] = true
      items[#items + 1] = { label = target, cmd = "make " .. target, cwd = dir, kind = "make" }
    end
  end
  return items
end

function detectors.just()
  local dir = root({ "justfile", "Justfile", ".justfile" })
  if not dir or vim.fn.executable("just") == 0 then return {} end
  local res = vim.system({ "just", "--summary" }, { cwd = dir, text = true }):wait()
  local items = {}
  for recipe in (res.stdout or ""):gmatch("%S+") do
    items[#items + 1] = { label = recipe, cmd = "just " .. recipe, cwd = dir, kind = "just" }
  end
  return items
end

function detectors.python()
  local dir = root({ "pyproject.toml", "requirements.txt", "setup.py", "manage.py" })
  if not dir then return {} end
  local runner = exists(dir .. "/uv.lock") and "uv run "
    or exists(dir .. "/poetry.lock") and "poetry run "
    or exists(dir .. "/.venv/bin/python") and ".venv/bin/"
    or ""
  local items = {}
  local function add(label, cmd) items[#items + 1] = { label = label, cmd = cmd, cwd = dir, kind = "python" } end

  -- Entry points declared in [project.scripts] / [tool.poetry.scripts]
  local pyproject = read(dir .. "/pyproject.toml") or ""
  local section
  for line in pyproject:gmatch("[^\n]+") do
    local header = line:match("^%[(.-)%]")
    if header then
      section = header
    elseif section == "project.scripts" or section == "tool.poetry.scripts" then
      local name = line:match("^%s*([%w_%-]+)%s*=")
      if name then add(name, (runner == ".venv/bin/" and ".venv/bin/" or runner) .. name) end
    end
  end

  local py = runner == ".venv/bin/" and ".venv/bin/python" or runner .. "python"
  if exists(dir .. "/manage.py") then
    add("runserver", py .. " manage.py runserver")
    add("migrate", py .. " manage.py migrate")
    add("makemigrations", py .. " manage.py makemigrations")
    add("shell", py .. " manage.py shell")
  end
  add("pytest", (runner == ".venv/bin/" and ".venv/bin/" or runner) .. "pytest")
  if exists(dir .. "/uv.lock") then add("uv sync", "uv sync") end
  if exists(dir .. "/poetry.lock") then add("poetry install", "poetry install") end
  if exists(dir .. "/requirements.txt") then add("pip install -r requirements.txt", py .. " -m pip install -r requirements.txt") end
  return items
end

function detectors.go()
  local dir = root({ "go.mod" })
  if not dir then return {} end
  local items = {}
  for _, c in ipairs({ "run .", "build ./...", "test ./...", "vet ./...", "mod tidy" }) do
    items[#items + 1] = { label = c, cmd = "go " .. c, cwd = dir, kind = "go" }
  end
  return items
end

function detectors.docker()
  local dir = root({ "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml" })
  if not dir then return {} end
  local items = {}
  for _, c in ipairs({ "up", "up -d", "up --build", "down", "logs -f", "ps" }) do
    items[#items + 1] = { label = c, cmd = "docker compose " .. c, cwd = dir, kind = "docker" }
  end
  return items
end

local icons = {
  npm = "\u{e71e}", pnpm = "\u{e71e}", yarn = "\u{e6a7}", bun = "\u{e76f}", deno = "\u{e7c0}", angular = "\u{e753}",
  cargo = "\u{e7a8}", maven = "\u{e738}", gradle = "\u{e738}", make = "\u{f0ad}", just = "\u{f0ad}",
  python = "\u{e73c}", go = "\u{e627}", docker = "\u{f308}", file = "\u{f15b}",
}

function M.run(task)
  if task.edit then
    -- Let the user finish the command (e.g. a component name) before running
    return vim.ui.input({ prompt = "Run: ", default = task.cmd }, function(cmd)
      if cmd and cmd ~= "" then M.run({ label = task.label, cmd = cmd, cwd = task.cwd, kind = task.kind }) end
    end)
  end
  last = task
  Snacks.terminal.open(task.cmd, {
    cwd = task.cwd,
    auto_close = false,
    win = { position = "bottom", height = 0.3, wo = { winbar = " " .. (icons[task.kind] or "") .. "  " .. task.cmd } },
  })
end

function M.pick()
  local items = {}
  for _, detect in pairs(detectors) do
    local ok, found = pcall(detect)
    if ok then vim.list_extend(items, found) end
  end
  if #items == 0 then
    return vim.notify("No package.json, Cargo.toml, pom.xml, build.gradle, Makefile, pyproject.toml… found", vim.log.levels.WARN)
  end
  for _, item in ipairs(items) do item.text = item.kind .. " " .. item.label .. " " .. item.cmd end

  Snacks.picker.pick({
    title = "Run task",
    items = items,
    layout = { preset = "select" },
    format = function(item)
      local ret = {
        { (icons[item.kind] or "\u{f04b}") .. " ", "Special" },
        { ("%-8s"):format(item.kind), "Comment" },
        { item.label, "Function" },
      }
      if item.detail then ret[#ret + 1] = { "  " .. item.detail, "Comment" } end
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then M.run(item) end
    end,
  })
end

function M.rerun()
  if not last then return M.pick() end
  M.run(last)
end

-- Run just the current file, based on its filetype
local file_cmds = {
  python = function(f) return (exists(vim.fn.getcwd() .. "/uv.lock") and "uv run " or "python3 ") .. f end,
  javascript = function(f) return "node " .. f end,
  typescript = function(f) return "npx --yes tsx " .. f end,
  java = function(f) return "java " .. f end, -- single-file source launcher
  rust = function(f) return vim.fs.root(0, { "Cargo.toml" }) and "cargo run" or ("rustc " .. f .. " -o /tmp/a.out && /tmp/a.out") end,
  go = function(f) return "go run " .. f end,
  lua = function(f) return "nvim -l " .. f end,
  sh = function(f) return "bash " .. f end,
  c = function(f) return "gcc " .. f .. " -o /tmp/a.out && /tmp/a.out" end,
  cpp = function(f) return "g++ " .. f .. " -o /tmp/a.out && /tmp/a.out" end,
}

function M.run_file()
  local get = file_cmds[vim.bo.filetype]
  if not get then return vim.notify("No runner for filetype " .. vim.bo.filetype, vim.log.levels.WARN) end
  vim.cmd("silent! write")
  M.run({ label = "file", kind = "file", cmd = get(vim.fn.shellescape(vim.fn.expand("%:p"))), cwd = vim.fn.getcwd() })
end

return M
