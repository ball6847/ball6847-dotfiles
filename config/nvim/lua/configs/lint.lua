local lint = require "lint"

lint.linters_by_ft = {
  markdown = { "codespell" },
  text = { "codespell" },
  go = { "codespell" },
  proto = { "codespell" },
  typescript = { "codespell" },
  javascript = { "codespell" },
  json = { "codespell" },
  yaml = { "codespell" },
  lua = { "codespell" }, -- Optional for Lua
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

-- Auto-run linting on save
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  group = lint_augroup,
  callback = function()
    require("lint").try_lint()
  end,
})

vim.keymap.set("n", "<leader>ll", function()
  lint.try_lint()
end, { desc = "Trigger linting for current file" })
