return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },

  -- https://www.youtube.com/watch?v=Irm2WELYSps&ab_channel=Dispatch
  {
    'smoka7/hop.nvim',
    version = "*",
    opts = {
      keys = 'etovxqpdygfblzhckisuran'
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
}
