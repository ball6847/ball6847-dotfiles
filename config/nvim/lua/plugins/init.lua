return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
  },
  -- conform - code formatter engine (actual config in lua/configs/conform.lua)
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    config = function()
      require "configs.conform"
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = {
        -- show dotfiles by default
        -- this will not need if this PR get released, https://github.com/NvChad/NvChad/issues/2975 (probably in v2.6)
        dotfiles = true,
      },
    },
  },

  -- hop - easymotion easy alternatives
  -- taken from: https://www.youtube.com/watch?v=Irm2WELYSps&ab_channel=Dispatch
  -- {
  --   "smoka7/hop.nvim",
  --   version = "*",
  --   keys = {
  --     {
  --       "<leader><leader>f",
  --       function()
  --         require("hop").hint_words()
  --       end,
  --       mode = {
  --         "n",
  --         "x",
  --         "o",
  --       },
  --     },
  --   },
  --   config = function()
  --     require("hop").setup {
  --       keys = "etovxqpdygfblzhckisuran",
  --       multi_windows = false,
  --     }
  --   end,
  -- },

  -- another hop or easymotion alternatives
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      -- { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      -- { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- require("nvchad.configs.lspconfig").defaults()
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
        "css-lsp",
        "prettier",
        "deno",
        "intelephense",
        "gopls",
        "svelte-language-server",
        "bash-language-server",
      },
    },
  },

  -- nvim-treesitter - syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "svelte",
        "typescript",
        "javascript",
        "go",
        "php",
        "yaml",
        "terraform",
      },
      highlight = {
        enable = true,
      },
    },
  },

  -- noice - notification
  -- NOTE: noice currently mess up choice selection at the moment, so we disable it for now
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
      stages = "static",
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      -- "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      -- `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      -- "rcarriga/nvim-notify",
    },
    config = function()
      require "configs.noice"
    end,
  },

  -- github colilot
  -- installation guide from https://www.reddit.com/r/neovim/comments/12vcybk/comment/jxjrdn5/
  -- see lua/mappings.lua for the keybinding (tldr: <C-l> to accept suggestion)
  -- use `:Copilot setup` command to setup the plugin
  {
    "github/copilot.vim",
    lazy = false,
    config = function()
      -- Mapping tab is already used by NvChad
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""
      -- The mapping is set to other key, see custom/lua/mappings
      -- or run <leader>ch to see copilot mapping section
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup {
        strategies = {
          chat = {
            adapter = "copilot",
          },
          inline = {
            adapter = "copilot",
          },
        },
      }
      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd [[cab cc CodeCompanion]]
    end,
  },

  -- nvim-spectre
  {
    "nvim-pack/nvim-spectre",
  },
  -- zen-mode
  {
    "folke/zen-mode.nvim",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  -- twilight dims inactive portions of the code
  -- {
  --   "folke/twilight.nvim",
  --   opts = {
  --     -- your configuration comes here
  --     -- or leave it empty to use the default settings
  --     -- refer to the configuration section below
  --   },
  -- },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require "configs.lint"
    end,
  },
  {
    "tanvirtin/vgit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    -- Lazy loading on 'VimEnter' event is necessary.
    event = "VimEnter",
    config = function()
      require("vgit").setup()
    end,
  },
  {
    "vim-test/vim-test",
    event = "VimEnter",
    init = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#go#runner"] = "gotest"
    end,
  },
  { "wakatime/vim-wakatime", lazy = false },
}
