-- Debugging: Python (debugpy), Rust/C (codelldb), JS/TS (js-debug), Java (via nvim-jdtls)
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" }, opts = {} },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
      { "jay-babu/mason-nvim-dap.nvim", dependencies = { "mason-org/mason.nvim" } },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run / continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      vim.fn.sign_define("DapBreakpoint", { text = "\u{f111}", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "󰁕", texthl = "DiagnosticWarn", linehl = "Visual" })

      dap.listeners.after.event_initialized.dapui = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui = function() dapui.close() end
      dap.listeners.before.event_exited.dapui = function() dapui.close() end

      -- Default adapter configs for anything Mason installed (debugpy, codelldb, js-debug)
      require("mason-nvim-dap").setup({ handlers = {} })
    end,
  },
}
