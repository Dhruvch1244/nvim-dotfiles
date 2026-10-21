-- ┌───────────────────────────────────────────────┐
-- │  Neovim — cyberdream void · animated · full IDE │
-- └───────────────────────────────────────────────┘
vim.loader.enable() -- byte-compile & cache lua modules for faster startup

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
require("config.fx").setup()
require("config.user").setup()
