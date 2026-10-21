local web = { "prettierd", "prettier", stop_after_first = true }

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, mode = { "n", "x" }, desc = "Format" },
      {
        "<leader>uf",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save " .. (vim.g.disable_autoformat and "off" or "on"))
        end,
        desc = "Toggle format on save",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_organize_imports", "ruff_format" },
        rust = { "rustfmt", lsp_format = "fallback" },
        javascript = web, javascriptreact = web, typescript = web, typescriptreact = web,
        html = web, htmlangular = web, css = web, scss = web, json = web, jsonc = web,
        yaml = web, markdown = web, graphql = web,
        toml = { "taplo" },
        sh = { "shfmt" },
        -- Java: formatted by jdtls (lsp fallback)
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function()
        if vim.g.disable_autoformat then return end
        return { timeout_ms = 1500 }
      end,
    },
  },
}
