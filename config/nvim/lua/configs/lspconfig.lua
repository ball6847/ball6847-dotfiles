require "configs.cmp"

local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").nn_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = { "lua_ls", "html", "cssls", "bashls" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

-- Function to check for the existence of deno.json
-- local function has_deno_json()
--   local current_dir = vim.fn.getcwd()
--   local deno_json = current_dir .. "/deno.json"
--   local deno_json_exists = vim.fn.filereadable(deno_json) == 1
--   return deno_json_exists
-- end

-- deno (typescript)
-- see https://docs.deno.com/runtime/manual/getting_started/setup_your_environment#vimneovim-via-plugins
-- note: denols will only enabled if the project root contains deno.json or deno.jsonc
--       and if your project also contains package.json as well, tsserver will be enabled as well and this will be mess. Make sure you don't have both deno.json and package.json in the same project

lspconfig.denols.setup {
  on_attach = on_attach,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
  settings = {
    deno = {
      enable = true,
      lint = true,
      config = "deno.json",
    },
  },
}

-- typescript
-- note: tsserver will be disabled if the project root contains deno.json or deno.jsonc

lspconfig.ts_ls.setup {
  on_attach = function(client, bufnr)
    if lspconfig.util.root_pattern("deno.json", "deno.jsonc")(vim.api.nvim_buf_get_name(bufnr)) then
      client.stop()
    else
      on_attach(client, bufnr)
    end
  end,
  on_init = on_init,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern "package.json",
  -- single_file_support = false,
}

-- svelte - configure on_attach with workaround for lsp not picking up ts/js changes.
-- see - https://github.com/neovim/nvim-lspconfig/issues/725#issuecomment-1837509673
lspconfig.svelte.setup {
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
  on_init = on_init,
  capabilities = capabilities,
}

-- intelephense (php)
lspconfig.intelephense.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
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
}

-- protols: detects the root directory by looking for protols.toml

lspconfig.protols.setup {
  root_dir = lspconfig.util.root_pattern "protols.toml",
}

-- gopls, setup integration with gofumpt and auto organize imports on save
-- see: https://github.com/golang/tools/blob/master/gopls/doc/vim.md

lspconfig.gopls.setup {
  on_attach = on_attach,
  -- on_attach = function(client, bufnr)
  --   vim.api.nvim_create_autocmd("BufWritePost", {
  --     pattern = { "*.go" },
  --     callback = function()
  --       on_attach(client, bufnr)
  --       local params = vim.lsp.util.make_range_params()
  --       params.context = { only = { "source.organizeImports" } }
  --       -- buf_request_sync defaults to a 1000ms timeout. Depending on your
  --       -- machine and codebase, you may want longer. Add an additional
  --       -- argument after params if you find that you have to write the file
  --       -- twice for changes to be saved.
  --       -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
  --       local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
  --       for cid, res in pairs(result or {}) do
  --         for _, r in pairs(res.result or {}) do
  --           if r.edit then
  --             local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
  --             vim.lsp.util.apply_workspace_edit(r.edit, enc)
  --           end
  --         end
  --       end
  --       vim.lsp.buf.format { async = false }
  --     end,
  --   })
  -- end,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      formatting = {
        goimportspath = "goimports",
      },
    },
  },
}
