local parsers = {
  "bash", "c", "css", "diff", "dockerfile", "git_config", "gitcommit", "gitignore", "go", "html",
  "angular", "java", "javascript", "jsdoc", "json", "lua", "luadoc", "markdown", "markdown_inline",
  "python", "query", "regex", "rust", "scss", "sql", "toml", "tsx", "typescript", "vim", "vimdoc",
  "xml", "yaml", "prisma", "graphql", "hurl",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      if vim.fn.executable("tree-sitter") == 1 then
        require("nvim-treesitter").install(parsers)
      else
        vim.schedule(function()
          vim.notify("tree-sitter CLI missing: run `sudo pacman -S tree-sitter-cli` for full highlighting", vim.log.levels.WARN)
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Auto close/rename HTML, JSX/TSX and Angular tags
  { "windwp/nvim-ts-autotag", event = { "BufReadPre", "BufNewFile" }, opts = {} },

  -- Sticky function/class header at top of window
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3 },
  },
}
