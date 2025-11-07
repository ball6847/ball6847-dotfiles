require "configs.cmp"

local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

-- Configure all LSPs with default settings using new Neovim 0.11+ API
vim.lsp.config("*", {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
})

-- Enable LSP servers with default config
local servers = { "html", "cssls", "bashls", "golangci_lint_ls" }
for _, server in ipairs(servers) do
  vim.lsp.enable(server)
end

-- Configure lua_ls with custom settings
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  }
})
vim.lsp.enable("lua_ls")

-- deno (typescript)
-- see https://docs.deno.com/runtime/manual/getting_started/setup_your_environment#vimneovim-via-plugins
-- note: denols will only enabled if the project root contains deno.json or deno.jsonc
--       and if your project also contains package.json as well, tsserver will be enabled as well and this will be mess. Make sure you don't have both deno.json and package.json in the same project

vim.lsp.config("denols", {
  root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc"),
  settings = {
    deno = {
      enable = true,
      lint = true,
      config = "deno.json",
    },
  },
})
vim.lsp.enable("denols")

-- typescript
-- note: tsserver will be disabled if the project root contains deno.json or deno.jsonc

vim.lsp.config("ts_ls", {
  root_dir = require("lspconfig.util").root_pattern "package.json",
  on_attach = function(client, bufnr)
    if require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")(vim.api.nvim_buf_get_name(bufnr)) then
      client.stop()
    else
      on_attach(client, bufnr)
    end
  end,
})
vim.lsp.enable("ts_ls")

-- svelte - configure on_attach with workaround for lsp not picking up ts/js changes.
-- see - https://github.com/neovim/nvim-lspconfig/issues/725#issuecomment-1837509673
vim.lsp.config("svelte", {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        -- Here use ctx.match instead of ctx.file
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
})
vim.lsp.enable("svelte")

-- intelephense (php)
vim.lsp.config("intelephense", {
  settings = {
    intelephense = {
      -- Add wordpress to the list of stubs
      stubs = {
        "apache",
        "bcmath",
        "bz2",
        "calendar",
        "com_dotnet",
        "Core",
        "ctype",
        "curl",
        "date",
        "dba",
        "dom",
        "enchant",
        "exif",
        "FFI",
        "fileinfo",
        "filter",
        "fpm",
        "ftp",
        "gd",
        "gettext",
        "gmp",
        "hash",
        "iconv",
        "imap",
        "intl",
        "json",
        "ldap",
        "libxml",
        "mbstring",
        "meta",
        "mysqli",
        "oci8",
        "odbc",
        "openssl",
        "pcntl",
        "pcre",
        "PDO",
        "pdo_ibm",
        "pdo_mysql",
        "pdo_pgsql",
        "pdo_sqlite",
        "pgsql",
        "Phar",
        "posix",
        "pspell",
        "readline",
        "Reflection",
        "session",
        "shmop",
        "SimpleXML",
        "snmp",
        "soap",
        "sockets",
        "sodium",
        "SPL",
        "sqlite3",
        "standard",
        "superglobals",
        "sysvmsg",
        "sysvsem",
        "sysvshm",
        "tidy",
        "tokenizer",
        "xml",
        "xmlreader",
        "xmlrpc",
        "xmlwriter",
        "xsl",
        "Zend OPcache",
        "zip",
        "zlib",
        "wordpress",
        "phpunit",
      },
      diagnostics = {
        enable = true,
      },
      format = {
        enable = true,
      },
    },
  },
})
vim.lsp.enable("intelephense")

-- protols: detects the root directory by looking for protols.toml
vim.lsp.config("protols", {
  root_dir = require("lspconfig.util").root_pattern "protols.toml",
})
vim.lsp.enable("protols")

-- gopls, setup integration with gofumpt and auto organize imports on save
-- see: https://github.com/golang/tools/blob/master/gopls/doc/vim.md
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      formatting = {
        goimportspath = "goimports",
      },
    },
  },
})
vim.lsp.enable("gopls")