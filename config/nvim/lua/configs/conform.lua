local conform = require "conform"

-- Helper function to detect if we're in a Deno project
local function is_deno_project()
  local root_markers = { "deno.json", "deno.jsonc" }
  local root_dir = vim.fs.find(root_markers, { upward = true, path = vim.fn.getcwd() })
  return #root_dir > 0
end

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    svelte = { "prettierd", "prettier" },
    javascript = { "prettierd", "prettier" },
    typescript = function()
      if is_deno_project() then
        return { "lsp" }  -- Use LSP formatter when Deno is detected
      else
        return { "prettierd", "prettier" }  -- Use Prettier for non-Deno projects
      end
    end,
    javascriptreact = { "prettierd", "prettier" },
    typescriptreact = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    graphql = { "prettierd", "prettier" },
    java = { "google-java-format" },
    kotlin = { "ktlint" },
    ruby = { "standardrb" },
    markdown = { "prettierd" },
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
