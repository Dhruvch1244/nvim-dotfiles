-- Language servers, formatters and debuggers installed via Mason.
-- Tools that need a missing runtime (node, java, …) are skipped instead of failing.
local has = function(bin) return vim.fn.executable(bin) == 1 end

local function mason_packages()
  local pkgs = {
    "lua-language-server", "stylua", "taplo", "marksman", "codelldb", "shfmt", -- standalone binaries
  }
  if has("npm") then
    vim.list_extend(pkgs, {
      "vtsls", "angular-language-server", "eslint-lsp", "tailwindcss-language-server",
      "html-lsp", "css-lsp", "json-lsp", "yaml-language-server", "emmet-language-server",
      "bash-language-server", "dockerfile-language-server", "prettierd", "js-debug-adapter",
    })
  end
  if has("python3") then
    vim.list_extend(pkgs, { "basedpyright", "ruff", "debugpy" })
  end
  if has("java") then
    vim.list_extend(pkgs, { "jdtls", "java-debug-adapter", "java-test" })
  end
  if has("go") then
    vim.list_extend(pkgs, { "gopls" })
  end
  return pkgs
end

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
    config = function(_, opts)
      require("mason").setup(opts)
      local registry = require("mason-registry")
      registry.refresh(function()
        for _, name in ipairs(mason_packages()) do
          local ok, pkg = pcall(registry.get_package, name)
          if ok and not pkg:is_installed() then
            vim.notify("Mason: installing " .. name)
            pkg:install()
          end
        end
      end)
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      -- Shared capabilities for every server
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      vim.lsp.config("lua_ls", {
        settings = { Lua = { workspace = { checkThirdParty = false }, hint = { enable = true } } },
      })

      local ts_inlay = {
        parameterNames = { enabled = "literals" },
        variableTypes = { enabled = false },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      }
      vim.lsp.config("vtsls", {
        settings = {
          complete_function_calls = true,
          vtsls = { autoUseWorkspaceTsdk = true, experimental = { completion = { enableServerSideFuzzyMatch = true } } },
          typescript = { inlayHints = ts_inlay, updateImportsOnFileMove = { enabled = "always" } },
          javascript = { inlayHints = ts_inlay, updateImportsOnFileMove = { enabled = "always" } },
        },
      })

      -- Use the project's .venv automatically
      vim.lsp.config("basedpyright", {
        settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
        before_init = function(_, config)
          local py = config.root_dir and (config.root_dir .. "/.venv/bin/python")
          if py and vim.uv.fs_stat(py) then
            config.settings.python = { pythonPath = py }
          end
        end,
      })

      -- package.json, tsconfig, docker-compose, GitHub Actions, … schemas
      vim.lsp.config("jsonls", {
        settings = { json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } } },
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = { schemaStore = { enable = false, url = "" }, schemas = require("schemastore").yaml.schemas() },
        },
      })

      -- Only start Angular's server inside Angular / Nx workspaces
      vim.lsp.config("angularls", { workspace_required = true })

      vim.lsp.config("tailwindcss", {
        settings = {
          tailwindCSS = { experimental = { classRegex = { { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" } } } },
        },
      })

      -- Enables every server Mason has installed. Java & Rust use dedicated plugins.
      require("mason-lspconfig").setup({
        automatic_enable = { exclude = { "jdtls", "rust_analyzer", "stylua" } },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp", { clear = true }),
        callback = function(ev)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = ev.buf, desc = desc })
          end
          map("gd", function() Snacks.picker.lsp_definitions() end, "Goto definition")
          map("gD", function() Snacks.picker.lsp_declarations() end, "Goto declaration")
          map("gr", function() Snacks.picker.lsp_references() end, "References")
          map("gI", function() Snacks.picker.lsp_implementations() end, "Goto implementation")
          map("gy", function() Snacks.picker.lsp_type_definitions() end, "Goto type definition")
          map("K", function() vim.lsp.buf.hover() end, "Hover docs")
          map("gK", vim.lsp.buf.signature_help, "Signature help")
          map("<C-k>", vim.lsp.buf.signature_help, "Signature help", "i")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "LSP info")

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
          end
        end,
      })
    end,
  },

  -- Lua dev for this config
  { "folke/lazydev.nvim", ft = "lua", opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } } },
}
