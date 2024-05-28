return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
      -- local conform = require("conform")

      -- conform.setup({
      --   formatters_by_ft = {
      --     lua = { "stylua" },
      --     svelte = { { "prettierd", "prettier" } },
      --     javascript = { { "prettierd", "prettier" } },
      --     typescript = { { "prettierd", "prettier" } },
      --     javascriptreact = { { "prettierd", "prettier" } },
      --     typescriptreact = { { "prettierd", "prettier" } },
      --     json = { { "prettierd", "prettier" } },
      --     graphql = { { "prettierd", "prettier" } },
      --     java = { "google-java-format" },
      --     kotlin = { "ktlint" },
      --     ruby = { "standardrb" },
      --     markdown = { { "prettierd", "prettier" } },
      --     erb = { "htmlbeautifier" },
      --     html = { "htmlbeautifier" },
      --     bash = { "beautysh" },
      --     proto = { "buf" },
      --     rust = { "rustfmt" },
      --     yaml = { "yamlfix" },
      --     toml = { "taplo" },
      --     css = { { "prettierd", "prettier" } },
      --     scss = { { "prettierd", "prettier" } },
      --     sh = { { "shellcheck" } },
      --   },
      -- })
      --
      -- vim.keymap.set({ "n", "v" }, "<leader>l", function()
      --   conform.format({
      --     lsp_fallback = true,
      --     async = false,
      --     timeout_ms = 1000,
      --   })
      -- end, { desc = "Format file or range (in visual mode)" })
    end,
  },

  -- https://www.youtube.com/watch?v=Irm2WELYSps&ab_channel=Dispatch
  {
    'smoka7/hop.nvim',
    version = "*",
    opts = {
      keys = 'etovxqpdygfblzhckisuran',
      multi_windows = true,
    },
    keys = {
      {
        "<leader>fg",
        function ()
          require("hop").hint_words()
        end,
        mode = {
          "n", "x", "o"
        }
      }
    }
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "html-lsp",
        "css-lsp" ,
        "prettier",
        "deno",
        "intelephense"
      },
    },
  },

  --
  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },

  -- noice
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
    config = function()
      require "configs.noice"
    end,
  },
}
