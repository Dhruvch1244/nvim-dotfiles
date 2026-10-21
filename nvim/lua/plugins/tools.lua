return {
  -- HTTP client: write requests in .hurl files and send them (<leader>R…)
  {
    "jellydn/hurl.nvim",
    ft = "hurl",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      mode = "split",
      show_notification = false,
      formatters = { json = { "jq" }, html = { "prettier", "--parser", "html" } },
    },
    keys = {
      {
        "<leader>Rb",
        function()
          local file = vim.fn.stdpath("data") .. "/scratch.hurl"
          local new = not vim.uv.fs_stat(file)
          vim.cmd.edit(file)
          if new then
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
              "# Put the cursor on a request and press <leader>Rs",
              "GET https://httpbin.org/json",
              "HTTP 200",
              "",
              "POST https://httpbin.org/post",
              "Content-Type: application/json",
              '{ "hello": "world" }',
            })
          end
        end,
        desc = "HTTP scratchpad",
      },
      { "<leader>Rs", "<cmd>HurlRunnerAt<cr>", desc = "Send request under cursor", ft = "hurl" },
      { "<leader>Ra", "<cmd>HurlRunner<cr>", desc = "Send all requests", ft = "hurl" },
      { "<leader>Rs", ":HurlRunner<cr>", desc = "Send selected requests", mode = "v", ft = "hurl" },
      { "<leader>Re", "<cmd>HurlRunnerToEntry<cr>", desc = "Run up to this request", ft = "hurl" },
      { "<leader>Rv", "<cmd>HurlVerbose<cr>", desc = "Verbose run (headers, timings)", ft = "hurl" },
      { "<leader>Rt", "<cmd>HurlToggleMode<cr>", desc = "Toggle split / popup", ft = "hurl" },
      { "<leader>RV", "<cmd>HurlManageVariable<cr>", desc = "Manage variables", ft = "hurl" },
      { "<leader>RE", "<cmd>HurlSetEnvFile<cr>", desc = "Set env file", ft = "hurl" },
    },
  },

  -- Database client: Postgres, MySQL/MariaDB, SQLite, … (<leader>D)
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = {
      { "tpope/vim-dadbod", cmd = "DB" },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },
    },
    keys = { { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Database UI" } },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod_ui"
      vim.g.db_ui_auto_execute_table_helpers = 1
      -- Local PostgreSQL over the unix socket (peer auth as your Linux user, no password).
      -- Add more with "Add connection" inside the UI; those are saved outside this config.
      local user = vim.env.USER or "postgres"
      vim.g.dbs = {
        { name = "local · " .. user, url = "postgresql:///" .. user },
        { name = "local · playground", url = "postgresql:///playground" },
      }
    end,
  },

  -- GitHub PRs & issues inside Neovim (uses your `gh` login)
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim", "nvim-tree/nvim-web-devicons" },
    opts = { picker = "snacks", enable_builtin = true, default_merge_method = "squash" },
    config = function(_, opts)
      require("octo").setup(opts)
      vim.treesitter.language.register("markdown", "octo")
    end,
    keys = {
      { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "Pull requests" },
      { "<leader>gP", "<cmd>Octo pr search<cr>", desc = "Search pull requests" },
      { "<leader>gn", "<cmd>Octo pr create<cr>", desc = "Create pull request" },
      { "<leader>gR", "<cmd>Octo review<cr>", desc = "Review current PR" },
      { "<leader>gi", "<cmd>Octo issue list<cr>", desc = "Issues" },
      { "<leader>gI", "<cmd>Octo issue search<cr>", desc = "Search issues" },
      { "<leader>gO", "<cmd>Octo<cr>", desc = "Octo actions" },
    },
  },

  -- Merge conflicts: co (ours) · ct (theirs) · cb (both) · c0 (none) · ]x / [x
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    opts = { default_mappings = true, disable_diagnostics = true },
    keys = { { "<leader>gx", "<cmd>GitConflictListQf<cr>", desc = "List merge conflicts" } },
  },

  -- Show colors for hex / rgb / hsl / Tailwind classes
  {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      render = "virtual",
      virtual_symbol = "■",
      virtual_symbol_position = "inline",
      enable_tailwind = true,
    },
    keys = { { "<leader>uc", "<cmd>HighlightColors Toggle<cr>", desc = "Toggle color preview" } },
  },

  -- Inline AI suggestions as you type. Accept with Alt-l.
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-w>",
          accept_line = "<M-j>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
      filetypes = { markdown = true, gitcommit = true, yaml = true, help = false },
    },
    init = function()
      -- Hide the ghost suggestion while the completion menu is open
      vim.api.nvim_create_autocmd("User", {
        pattern = "BlinkCmpMenuOpen",
        callback = function() vim.b.copilot_suggestion_hidden = true end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "BlinkCmpMenuClose",
        callback = function() vim.b.copilot_suggestion_hidden = false end,
      })
    end,
    keys = {
      {
        "<leader>uA",
        function()
          require("copilot.suggestion").toggle_auto_trigger()
          vim.notify("Copilot auto-suggest toggled")
        end,
        desc = "Toggle AI suggestions",
      },
    },
  },

  -- Pin files and jump between them instantly
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("harpoon"):setup({ settings = { save_on_toggle = true } }) end,
    keys = function()
      local keys = {
        { "<leader>H", function() require("harpoon"):list():add() end, desc = "Pin file (harpoon)" },
        {
          "<C-e>",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Pinned files menu",
        },
      }
      for i = 1, 5 do
        keys[#keys + 1] = { "<leader>" .. i, function() require("harpoon"):list():select(i) end, desc = "Pinned file " .. i }
      end
      return keys
    end,
  },

  -- Docker containers, images, logs
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>od",
        function()
          if vim.fn.executable("lazydocker") == 0 then
            return vim.notify("lazydocker is not installed", vim.log.levels.WARN)
          end
          Snacks.terminal("lazydocker", { win = { position = "float", width = 0.9, height = 0.9 } })
        end,
        desc = "Docker (lazydocker)",
      },
    },
  },
}
