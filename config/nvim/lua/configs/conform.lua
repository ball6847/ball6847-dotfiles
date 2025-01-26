local conform = require "conform"

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    svelte = { "prettierd", "prettier" },
    javascript = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    -- typescript = { "lsp" },
    javascriptreact = { "prettierd", "prettier" },
    typescriptreact = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    graphql = { "prettierd", "prettier" },
    java = { "google-java-format" },
    kotlin = { "ktlint" },
    ruby = { "standardrb" },
    markdown = { "prettierd", "prettier" },
    erb = { "htmlbeautifier" },
    html = { "htmlbeautifier" },
    bash = { "beautysh" },
    proto = { "buf" },
    rust = { "rustfmt" },
    yaml = { "yamlfix" },
    toml = { "taplo" },
    css = { "prettierd", "prettier" },
    scss = { "prettierd", "prettier" },
    sh = { "shellcheck" },
    php = { "lsp" },
    go = { "lsp" },
  },
  stop_after_first = true,
  format_on_save = {
    lsp_fallback = true,
    async = false,
    timeout_ms = 1000,
  },
}

vim.keymap.set({ "n", "v" }, "<leader>l", function()
  conform.format {
    lsp_fallback = true,
    async = false,
    timeout_ms = 1000,
  }
end, { desc = "Format file or range (in visual mode)" })

conform.setup(options)
