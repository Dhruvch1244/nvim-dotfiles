local opt = vim.opt

-- Make toolchains visible even when Neovim isn't started from a login shell
for _, dir in ipairs({ "/usr/lib/rustup/bin", vim.env.HOME .. "/.cargo/bin", vim.env.HOME .. "/.local/bin" }) do
  if vim.uv.fs_stat(dir) and not vim.env.PATH:find(dir, 1, true) then
    vim.env.PATH = dir .. ":" .. vim.env.PATH
  end
end

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false -- lualine shows it
opt.laststatus = 3 -- one global statusline
opt.cmdheight = 1
opt.pumheight = 12
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.fillchars = { eob = " ", fold = " ", foldopen = "\u{f47c}", foldclose = "\u{f460}", foldsep = " " }
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.winborder = "rounded"

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.shiftround = true
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- live preview of :s
opt.virtualedit = "block"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.confirm = true

-- Files & performance
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.updatetime = 200
opt.timeoutlen = 300
opt.autowrite = true

-- Folding (treesitter, all open by default)
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""

-- Grep with ripgrep
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, prefix = "●" },
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "\u{f057} ",
      [vim.diagnostic.severity.WARN] = "\u{f071} ",
      [vim.diagnostic.severity.HINT] = "\u{f0eb} ",
      [vim.diagnostic.severity.INFO] = "\u{f05a} ",
    },
  },
})
