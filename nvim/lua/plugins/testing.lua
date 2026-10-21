-- Test runner: Jest, Vitest, pytest, Rust (cargo/nextest) and JUnit, with debug support
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-python",
      "rcasia/neotest-java",
    },
    cmd = { "Neotest", "NeotestJava" },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-vitest"),
          require("neotest-jest")({ jestCommand = "npx jest" }),
          require("neotest-python")({ runner = "pytest", dap = { justMyCode = false } }),
          require("rustaceanvim.neotest"),
          require("neotest-java")({}),
        },
        status = { virtual_text = true },
        output = { open_on_run = true },
        quickfix = { open = false },
      })
    end,
    keys = {
      { "<leader>Tr", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>Tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
      { "<leader>TT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all tests" },
      { "<leader>Tl", function() require("neotest").run.run_last() end, desc = "Rerun last" },
      { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Test summary panel" },
      { "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Test output" },
      { "<leader>TO", function() require("neotest").output_panel.toggle() end, desc = "Output panel" },
      { "<leader>Tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Watch file" },
      { "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop" },
      { "]T", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
      { "[T", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev failed test" },
    },
  },
}
