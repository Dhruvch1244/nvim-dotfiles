return {
  -- File tree: <space>e   (press ? inside the tree for every mapping)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle left<cr>", desc = "File tree" },
      { "<leader>E", "<cmd>Neotree reveal left<cr>", desc = "Reveal file in tree" },
      { "<leader>fe", "<cmd>Neotree toggle float reveal<cr>", desc = "File tree (float)" },
      { "<leader>fE", "<cmd>Neotree toggle right<cr>", desc = "File tree (right)" },
      { "<leader>be", "<cmd>Neotree toggle buffers left<cr>", desc = "Buffer tree" },
      { "<leader>ge", "<cmd>Neotree toggle git_status float<cr>", desc = "Git changes tree" },
      { "<leader>cs", "<cmd>Neotree toggle document_symbols right<cr>", desc = "Symbols outline (tree)" },
    },
    init = function()
      -- Open the tree instead of netrw when starting with `nvim <dir>`
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("neotree_start", { clear = true }),
        callback = function()
          local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(0))
          if stat and stat.type == "directory" then
            vim.api.nvim_del_augroup_by_name("neotree_start")
            require("neo-tree")
          end
        end,
      })
    end,
    opts = function()
      -- Directory of the node under the cursor (the node itself if it is a directory)
      local function node_dir(state)
        local node = state.tree:get_node()
        return node.type == "directory" and node.path or vim.fn.fnamemodify(node.path, ":h")
      end

      return {
        close_if_last_window = true,
        enable_opened_markers = true,
        popup_border_style = "rounded",
        sources = { "filesystem", "buffers", "git_status", "document_symbols" },
        source_selector = {
          winbar = true,
          sources = {
            { source = "filesystem", display_name = " \u{f07b} Files " },
            { source = "buffers", display_name = " \u{f0c5} Buffers " },
            { source = "git_status", display_name = " \u{e702} Git " },
            { source = "document_symbols", display_name = " \u{f0ca} Symbols " },
          },
        },
        enable_diagnostics = true,
        enable_git_status = true,
        sort_case_insensitive = true,

        commands = {
          -- Copy path in several formats
          copy_path = function(state)
            local path = state.tree:get_node().path
            local cwd = vim.fn.getcwd()
            local choices = {
              { "Absolute path", path },
              { "Relative path", vim.fn.fnamemodify(path, ":.") },
              { "File name", vim.fn.fnamemodify(path, ":t") },
              { "Name without extension", vim.fn.fnamemodify(path, ":t:r") },
              { "Path from home", vim.fn.fnamemodify(path, ":~") },
              { "Directory", vim.fn.fnamemodify(path, ":h") },
              { "Project root", cwd },
            }
            vim.ui.select(choices, {
              prompt = "Copy to clipboard",
              format_item = function(c) return ("%-24s %s"):format(c[1], c[2]) end,
            }, function(choice)
              if not choice then return end
              vim.fn.setreg("+", choice[2])
              vim.notify("Copied: " .. choice[2])
            end)
          end,
          system_open = function(state) vim.ui.open(state.tree:get_node().path) end,
          find_in_dir = function(state) Snacks.picker.files({ cwd = node_dir(state) }) end,
          grep_in_dir = function(state) Snacks.picker.grep({ dirs = { node_dir(state) } }) end,
          replace_in_dir = function(state)
            require("grug-far").open({ prefills = { paths = node_dir(state) } })
          end,
          terminal_here = function(state)
            Snacks.terminal(nil, { cwd = node_dir(state), win = { position = "float" } })
          end,
          git_history = function(state)
            vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(state.tree:get_node().path))
          end,
          -- Safer delete: move to the system trash (restorable from Dolphin)
          trash = function(state)
            local node = state.tree:get_node()
            if node.type == "message" then return end
            local name = vim.fn.fnamemodify(node.path, ":t")
            vim.ui.select({ "Yes", "No" }, { prompt = "Move " .. name .. " to trash?" }, function(choice)
              if choice ~= "Yes" then return end
              local res = vim.system({ "gio", "trash", node.path }):wait()
              if res.code ~= 0 then return vim.notify(res.stderr, vim.log.levels.ERROR) end
              require("neo-tree.sources.manager").refresh(state.name)
            end)
          end,
          add_to_claude = function() vim.cmd("ClaudeCodeTreeAdd") end,
        },

        window = {
          width = 34,
          mappings = {
            ["l"] = "open",
            ["<cr>"] = "open",
            ["h"] = "close_node",
            ["<space>"] = "none",
            ["P"] = { "toggle_preview", config = { use_float = true } },
            ["<C-v>"] = "open_vsplit",
            ["<C-x>"] = "open_split",
            ["<C-t>"] = "open_tabnew",
            ["Z"] = "expand_all_nodes",
            ["z"] = "close_all_nodes",
            ["Y"] = "copy_path",
            ["O"] = "system_open",
            ["T"] = "terminal_here",
            ["ff"] = "find_in_dir",
            ["fg"] = "grep_in_dir",
            ["fr"] = "replace_in_dir",
            ["gh"] = "git_history",
            ["d"] = "trash",
            ["D"] = "delete", -- permanent delete
            ["A"] = "add_to_claude",
            ["<"] = "prev_source",
            [">"] = "next_source",
            ["+"] = function() vim.cmd("vertical resize +5") end,
            ["-"] = function() vim.cmd("vertical resize -5") end,
          },
        },

        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          hijack_netrw_behavior = "open_current",
          group_empty_dirs = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = { ".git", "node_modules", ".DS_Store" },
            never_show = { ".DS_Store" },
          },
        },

        buffers = { follow_current_file = { enabled = true } },
        document_symbols = { follow_cursor = true },

        default_component_configs = {
          indent = { with_expanders = true },
          -- Files you've opened stay highlighted (magenta italic), even after closing them
          name = { highlight_opened_files = "all", use_git_status_colors = true },
          modified = { symbol = "\u{f111}" },
          file_size = { enabled = true, required_width = 50 },
          last_modified = { enabled = true, required_width = 70 },
          git_status = {
            symbols = { unstaged = "󰄱", staged = "󰱒" },
          },
        },
      }
    end,
  },

  -- Project-wide search & replace
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = { headerMaxWidth = 80 },
    keys = {
      { "<leader>sR", function() require("grug-far").open() end, desc = "Search & replace (project)", mode = { "n", "x" } },
      {
        "<leader>sF",
        function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end,
        desc = "Search & replace (file)",
      },
    },
  },

  -- Jump anywhere on screen
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
    },
  },

  -- Diagnostics / references list
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (project)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols outline" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    },
  },

  -- TODO / FIXME / HACK highlighting & search
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo comments" },
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo" },
    },
  },

  -- Small, fast editing helpers
  { "echasnovski/mini.pairs", event = "InsertEnter", opts = {} },
  { -- gsa / gsd / gsr  (s is taken by flash)
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa", delete = "gsd", find = "gsf", find_left = "gsF",
        highlight = "gsh", replace = "gsr", update_n_lines = "gsn",
      },
    },
  },
  { "echasnovski/mini.ai", event = "VeryLazy", opts = { n_lines = 500 } }, -- better a/i textobjects

  -- Sessions
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    },
  },
}
