return {
  -- Rust: rust-analyzer, runnables, macro expansion, debugging via codelldb
  {
    "mrcjkb/rustaceanvim",
    lazy = false, -- the plugin lazy-loads itself on rust files
    init = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(_, buf)
            local map = function(k, cmd, desc) vim.keymap.set("n", k, cmd, { buffer = buf, desc = desc }) end
            map("<leader>ca", function() vim.cmd.RustLsp("codeAction") end, "Code action (Rust)")
            map("<leader>dr", function() vim.cmd.RustLsp("debuggables") end, "Rust debuggables")
            map("<leader>cx", function() vim.cmd.RustLsp("runnables") end, "Rust runnables")
            map("<leader>ce", function() vim.cmd.RustLsp("expandMacro") end, "Expand macro")
          end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              check = { command = "clippy" },
            },
          },
        },
      }
    end,
  },
  { "saecki/crates.nvim", event = "BufRead Cargo.toml", opts = { completion = { crates = { enabled = true } } } },

  -- Java: Eclipse JDT LS with debugging & test support
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local mason = vim.fn.stdpath("data") .. "/mason"

      local function start()
        local jdtls = mason .. "/bin/jdtls"
        if vim.fn.executable(jdtls) == 0 then
          return vim.notify("jdtls not installed (needs a JDK: sudo pacman -S jdk-openjdk)", vim.log.levels.WARN)
        end
        local root = vim.fs.root(0, { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
          or vim.fn.getcwd()
        local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. root:gsub("/", "%%")

        local bundles = vim.fn.glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
        vim.list_extend(bundles, vim.fn.glob(mason .. "/packages/java-test/extension/server/*.jar", true, true))

        require("jdtls").start_or_attach({
          cmd = { jdtls, "-data", workspace },
          root_dir = root,
          capabilities = require("blink.cmp").get_lsp_capabilities(),
          init_options = { bundles = bundles },
          settings = {
            java = {
              inlayHints = { parameterNames = { enabled = "all" } },
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" },
              sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
            },
          },
          on_attach = function(_, buf)
            local j = require("jdtls")
            if #bundles > 0 then j.setup_dap({ hotcodereplace = "auto" }) end
            local map = function(mode, k, fn, desc) vim.keymap.set(mode, k, fn, { buffer = buf, desc = desc }) end
            map("n", "<leader>co", j.organize_imports, "Organize imports")
            map({ "n", "x" }, "<leader>cv", j.extract_variable, "Extract variable")
            map({ "n", "x" }, "<leader>cc", j.extract_constant, "Extract constant")
            map("x", "<leader>cm", function() j.extract_method(true) end, "Extract method")
            map("n", "<leader>dT", j.test_class, "Debug test class")
            map("n", "<leader>dM", j.test_nearest_method, "Debug nearest test")
          end,
        })
      end

      vim.api.nvim_create_autocmd("FileType", { pattern = "java", callback = start })
      start()
    end,
  },

  -- Markdown preview in the browser, live-synced with scrolling
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = "markdown",
    build = "cd app && npm install --no-audit --no-fund",
    init = function()
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Preview in browser" },
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle in-editor rendering" },
    },
  },

  -- Markdown rendered inside the buffer
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    opts = { completions = { blink = { enabled = true } } },
  },
}
