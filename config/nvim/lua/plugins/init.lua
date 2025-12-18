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
      view = {
        width = 40,
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
        "gofumpt",
        "svelte-language-server",
        "bash-language-server",
        "beautysh",
        "google-java-format",
        "htmlbeautifier",
        "ktlint",
        "prettierd",
        "shellcheck",
        "standardrb",
        "stylua",
        "taplo",
        "typescript-language-server",
        "yamlfix",
        "codespell",
        "protols",
        "golangci-lint-langserver",
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
    "vim-test/vim-test",
    event = "VimEnter",
    init = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#go#gotest#options"] = "-coverprofile=cover.out"
    end,
  },
  {
    "wakatime/vim-wakatime",
    lazy = false,
  },
  -- :CoverageLoad to load coverage file
  -- :CoverageShow to show coverage in the buffer
  -- :CoverageToggle to toggle coverage display
  {
    "andythigpen/nvim-coverage",
    version = "*",
    lazy = false,
    config = function()
      local go_coverage_file = "cover.out"
      require("coverage").setup {
        commands = true,
        auto_reload = true,
        lang = {
          go = {
            coverage_file = go_coverage_file,
          },
        },
      }
      -- Auto run test and show coverage on entering a Go file
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*.go",
        callback = function()
          if vim.fn.filereadable(go_coverage_file) == 1 then
            require("coverage").load(true)
            require("coverage").show()
          end
        end,
      })
    end,
  },
  -- Opencode integration, setup snippet copied from https://github.com/NickvanDyke/opencode.nvim?tab=readme-ov-file#-setup
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      -- Recommended for `ask()` and `select()`.
      -- Required for default `toggle()` implementation.
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
      }

      -- Required for `opts.auto_reload`.
      vim.o.autoread = true

      -- Keymaps moved to lua/mappings.lua for better organization
    end,
  },
  -- hot-reload.nvim - reload neovim config on the fly
  -- NOTE: Keep this list updated when adding/removing config files
  -- The plugin uses pcall, so missing files won't crash but will show errors
  {
    "Zeioth/hot-reload.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufEnter",
    opts = function()
      local config_dir = vim.fn.stdpath "config" .. "/lua/"
      return {
        reload_files = {
          config_dir .. "options.lua",
          config_dir .. "mappings.lua",
          config_dir .. "configs/lspconfig.lua",
          config_dir .. "configs/cmp.lua",
          config_dir .. "configs/conform.lua",
          config_dir .. "configs/noice.lua",
          config_dir .. "configs/scrollbar.lua",
          config_dir .. "configs/lint.lua",
          config_dir .. "configs/gitsigns.lua",
          config_dir .. "configs/autoread.lua",
          config_dir .. "configs/lazy.lua",
          config_dir .. "configs/copy-reference-enhanced.lua",
        },
        reload_callback = function()
          vim.cmd(":silent! colorscheme " .. vim.g.default_colorscheme)
          vim.cmd ":silent! doautocmd ColorScheme"
        end,
      }
    end,
  },
  -- toggleterm - terminal management
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { "<C-\\>", "<Cmd>ToggleTerm<CR>", mode = { "n", "t" }, desc = "Toggle terminal" },
      -- { "<leader>t", "<Cmd>ToggleTerm<CR>", mode = { "n", "t" }, desc = "Toggle terminal" },
      {
        "<F3>",
        function()
          local Terminal = require("toggleterm.terminal").Terminal

          -- Create a dedicated fullscreen terminal
          local fullscreen_term = Terminal:new {
            direction = "float",
            float_opts = {
              border = "curved",
              width = math.ceil(vim.o.columns * 0.9),
              height = math.ceil(vim.o.lines * 0.9),
              row = math.ceil(vim.o.lines * 0.05),
              col = math.ceil(vim.o.columns * 0.05),
              winblend = 0,
              highlights = {
                border = "Normal",
                background = "Normal",
              },
            },
          }

          fullscreen_term:toggle()
        end,
        mode = { "n", "t" },
        desc = "Toggle fullscreen terminal",
      },
    },
    config = function()
      require("toggleterm").setup {
        size = 20,
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = false,
        direction = "horizontal",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          width = math.ceil(vim.o.columns * 0.9),
          height = math.ceil(vim.o.lines * 0.9),
          row = math.ceil(vim.o.lines * 0.05), -- Center vertically (5% from top)
          col = math.ceil(vim.o.columns * 0.05), -- Center horizontally (5% from left)
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      }
    end,
  },

  -- nvim-scrollbar
  {
    "petertriho/nvim-scrollbar",
    event = "VeryLazy",
    config = function()
      -- Load custom highlights first
      require "configs.scrollbar"

      require("scrollbar").setup {
        handle = {
          text = "█", -- Changed from " " to "█" for better visibility
          blend = 0, -- Changed from 30 to 0 for full opacity
          highlight = "ScrollbarHandle",
        },
        marks = {
          Cursor = {
            text = "█", -- Changed from "•" to "█" for better visibility
            priority = 0,
            highlight = "ScrollbarCursor",
          },
          Search = {
            text = { "█", "█" }, -- Changed from {"-", "="} to solid blocks
            priority = 1,
            highlight = "ScrollbarSearch",
          },
          Error = {
            text = { "█", "█" }, -- Changed from {"-", "="} to solid blocks
            priority = 2,
            highlight = "ScrollbarError",
          },
          Warn = {
            text = { "█", "█" }, -- Changed from {"-", "="} to solid blocks
            priority = 3,
            highlight = "ScrollbarWarn",
          },
          Info = {
            text = { "█", "█" }, -- Changed from {"-", "="} to solid blocks
            priority = 4,
            highlight = "ScrollbarInfo",
          },
          Hint = {
            text = { "█", "█" }, -- Changed from {"-", "="} to solid blocks
            priority = 5,
            highlight = "ScrollbarHint",
          },
          Misc = {
            text = { "█", "█" }, -- Changed from {"-", "="} to solid blocks
            priority = 6,
            highlight = "ScrollbarMisc",
          },
          GitAdd = {
            text = "█", -- Changed from "┆" to "█" for better visibility
            priority = 7,
            highlight = "ScrollbarGitAdd",
          },
          GitChange = {
            text = "█", -- Changed from "┆" to "█" for better visibility
            priority = 7,
            highlight = "ScrollbarGitChange",
          },
          GitDelete = {
            text = "█", -- Changed from "▁" to "█" for better visibility
            priority = 7,
            highlight = "ScrollbarGitDelete",
          },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true, -- Enable git signs if you have gitsigns
          handle = true,
          search = true, -- Enable search marks if you have nvim-hlslens
          ale = false,
        },
        excluded_filetypes = { "NvimTree" },
        set_highlights = false, -- We'll set our own highlights
      }
    end,
  },

  -- vscode-diff.nvim - VSCode-style side-by-side diff view
  {
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
      require("vscode-diff").setup {
        -- Highlight configuration
        highlights = {
          -- Line-level: accepts highlight group names or hex colors (e.g., "#2ea043")
          line_insert = "DiffAdd", -- Line-level insertions
          line_delete = "DiffDelete", -- Line-level deletions

          -- Character-level: accepts highlight group names or hex colors
          -- If specified, these override char_brightness calculation
          char_insert = nil, -- Character-level insertions (nil = auto-derive)
          char_delete = nil, -- Character-level deletions (nil = auto-derive)

          -- Brightness multiplier (only used when char_insert/char_delete are nil)
          -- nil = auto-detect based on background (1.4 for dark, 0.92 for light)
          char_brightness = 1.4, -- Auto-adjust based on your colorscheme
        },

        -- Diff view behavior
        diff = {
          disable_inlay_hints = true, -- Disable inlay hints in diff windows for cleaner view
          max_computation_time_ms = 5000, -- Maximum time for diff computation (VSCode default)
        },

        -- Keymaps in diff view
        keymaps = {
          view = {
            quit = "q", -- Close diff tab
            toggle_explorer = "<leader>b", -- Toggle explorer visibility (explorer mode only)
            next_hunk = "]c", -- Jump to next change
            prev_hunk = "[c", -- Jump to previous change
            next_file = "]f", -- Next file in explorer mode
            prev_file = "[f", -- Previous file in explorer mode
          },
          explorer = {
            select = "<CR>", -- Open diff for selected file
            hover = "K", -- Show file diff preview
            refresh = "R", -- Refresh git status
          },
        },
      }
    end,
  },
}
