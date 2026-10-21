return {
  -- Theme
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      local p = require("config.fx").palette
      return {
        variant = "default",
        transparent = false,
        italic_comments = true,
        hide_fillchars = true,
        terminal_colors = true,
        -- "Void" variant: near-black space instead of cyberdream's grey
        colors = { bg = p.void, bg_alt = p.deep, bg_highlight = p.hull, grey = p.dust },
        overrides = function()
          return {
            NormalFloat = { bg = p.deep },
            FloatBorder = { fg = p.violet, bg = p.deep },
            FloatTitle = { fg = p.void, bg = p.violet, bold = true },
            WinSeparator = { fg = p.rim },
            Visual = { bg = "#2a1748" },
            Search = { fg = p.void, bg = p.cyan },
            IncSearch = { fg = p.void, bg = p.magenta, bold = true },
            Pmenu = { bg = p.deep },
            PmenuSel = { fg = p.void, bg = p.violet, bold = true },
            LineNr = { fg = "#2e333d" },
            NeoTreeNormal = { bg = p.deep },
            NeoTreeNormalNC = { bg = p.deep },
            NeoTreeWinSeparator = { fg = p.deep, bg = p.deep },
            NeoTreeFileNameOpened = { fg = p.magenta, italic = true, bold = true },
            NeoTreeCursorLine = { bg = p.hull },
            SnacksPickerBorder = { fg = p.violet },
            SnacksPickerTitle = { fg = p.void, bg = p.magenta, bold = true },
            SnacksPickerMatch = { fg = p.magenta, bold = true },
            SnacksIndent = { fg = "#16191f" },
            SnacksIndentScope = { fg = p.violet },
            SnacksDashboardKey = { fg = p.magenta, bold = true },
            SnacksDashboardIcon = { fg = p.cyan },
            SnacksDashboardDesc = { fg = "#c8ccd4" },
            SnacksDashboardFile = { fg = "#c8ccd4" },
            SnacksDashboardDir = { fg = p.dust },
            SnacksDashboardTitle = { fg = p.violet, bold = true },
            SnacksDashboardFooter = { fg = p.dust, italic = true },
          }
        end,
      }
    end,
    config = function(_, opts)
      require("cyberdream").setup(opts)
      vim.cmd.colorscheme("cyberdream")
    end,
  },

  -- Animated smear cursor: a comet tail that sheds stardust (color follows the mode)
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      smear_insert_mode = true,
      smear_to_cmd = true,
      scroll_buffer_space = true,
      cursor_color = require("config.fx").palette.cyan,
      normal_bg = require("config.fx").palette.void,
      -- Comet motion: snappy head, long elastic tail
      stiffness = 0.7,
      trailing_stiffness = 0.3,
      trailing_exponent = 4,
      damping = 0.8,
      anticipation = 0.25,
      gradient_exponent = 0,
      max_length = 32,
      distance_stop_animating = 0.3,
      -- Stardust explosion: dense bursts that spray wide, float upward and linger
      particles_enabled = true,
      never_draw_over_target = true,
      particles_over_text = true,
      particle_max_num = 500,
      particle_spread = 1,
      particles_per_second = 1500,
      particles_per_length = 4,
      particle_max_lifetime = 1300,
      particle_lifetime_distribution_exponent = 1.5,
      particle_max_initial_velocity = 28,
      particle_velocity_from_cursor = 0.6,
      particle_random_velocity = 220,
      particle_damping = 0.1,
      particle_gravity = -45,
      min_distance_emit_particles = 0.4,
      time_interval = 7, -- ~144 fps
      -- Reuse particle windows instead of creating/destroying hundreds per frame
      max_kept_windows = 600,
      filetypes_disabled = { "snacks_dashboard", "lazy", "mason" },
    },
    config = function(_, opts)
      require("smear_cursor").setup(opts)
      require("config.fx").paint_mode()
    end,
    keys = {
      { "<leader>uS", "<cmd>SmearCursorToggle<cr>", desc = "Toggle smear cursor" },
    },
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = "",
        section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" },
        disabled_filetypes = { statusline = { "snacks_dashboard" } },
      },
      sections = {
        lualine_a = {
          {
            "mode",
            separator = { left = "\u{e0b6}" },
            right_padding = 2,
            -- Same color as the cursor for the current mode
            color = function()
              local fx = require("config.fx")
              return { fg = fx.palette.void, bg = fx.mode_color(), gui = "bold" }
            end,
          },
        },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = {
          { "filename", path = 1 },
          -- Where you came from: <leader>bb jumps back to it
          {
            function() return require("config.fx").prev_file() end,
            color = { fg = require("config.fx").palette.dust, gui = "italic" },
          },
        },
        lualine_x = {
          {
            function()
              local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
              return #names > 0 and ("\u{f013} " .. table.concat(names, ", ")) or ""
            end,
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { { "location", separator = { right = "\u{e0b4}" }, left_padding = 2 } },
      },
      extensions = { "neo-tree", "lazy", "trouble", "quickfix" },
    },
  },

  -- Buffer tabs
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin buffer" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        separator_style = "thin",
        close_command = function(n) Snacks.bufdelete(n) end,
        offsets = {
          { filetype = "neo-tree", text = "\u{e5ff}  Explorer", highlight = "Directory", text_align = "left" },
        },
      },
    },
  },

  -- Keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        { "<leader>a", group = "AI / Claude Code", icon = "󰚩 " },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunks" },
        { "<leader>m", group = "markdown" },
        { "<leader>o", group = "tools" },
        { "<leader>q", group = "quit/session" },
        { "<leader>R", group = "HTTP client" },
        { "<leader>T", group = "tests" },
        { "<leader>r", group = "run" },
        { "<leader>s", group = "search / grep" },
        { "<leader>t", group = "terminal" },
        { "<leader>u", group = "toggles" },
        { "<leader>x", group = "diagnostics" },
      },
    },
  },

  { "nvim-tree/nvim-web-devicons" },
}
