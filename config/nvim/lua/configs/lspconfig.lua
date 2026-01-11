-- LSP Configuration using nvim-lspconfig plugin
-- Import and configure LSP servers from the nvim-lspconfig plugin

-- Configure all LSPs with default settings using new Neovim 0.11+ API
vim.lsp.config("*", {
  on_attach = require("nvchad.configs.lspconfig").on_attach,
  on_init = require("nvchad.configs.lspconfig").on_init,
  capabilities = require("nvchad.configs.lspconfig").capabilities,
})

-- Enable LSP servers with default config from nvim-lspconfig
local servers = {
  "html",
  "cssls",
  "bashls",
  "lua_ls",
  "denols",
  "ts_ls",
  "svelte",
  "intelephense",
  "protols",
  "gopls",
}

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
  },
})

-- Configure gopls with gofumpt integration
vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      formatting = {
        goimportspath = "goimports",
      },
    },
  },
})

-- Configure intelephense with WordPress stubs
vim.lsp.config("intelephense", {
  settings = {
    intelephense = {
      stubs = {
        "apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core", "ctype", "curl",
        "date", "dba", "dom", "enchant", "exif", "FFI", "fileinfo", "filter", "fpm",
        "ftp", "gd", "gettext", "gmp", "hash", "iconv", "imap", "intl", "json", "ldap",
        "libxml", "mbstring", "meta", "mysqli", "oci8", "odbc", "openssl", "pcntl",
        "pcre", "PDO", "pdo_ibm", "pdo_mysql", "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar",
        "posix", "pspell", "readline", "Reflection", "session", "shmop", "SimpleXML",
        "snmp", "soap", "sockets", "sodium", "SPL", "sqlite3", "standard", "superglobals",
        "sysvmsg", "sysvsem", "sysvshm", "tidy", "tokenizer", "xml", "xmlreader", "xmlrpc",
        "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib", "wordpress", "phpunit",
      },
      diagnostics = { enable = true },
      format = { enable = true },
    },
  },
})

-- Configure svelte with TypeScript/JavaScript file change handling
vim.lsp.config("svelte", {
  on_attach = function(client, bufnr)
    -- Default on_attach handling
    if client.config.on_attach then
      client.config.on_attach(client, bufnr)
    end
    
    -- Handle TypeScript/JavaScript file changes
    vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = bufnr,
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
})

-- Configure denols with settings from nvim-lspconfig
vim.lsp.config("denols", {
  settings = {
    deno = {
      enable = true,
      lint = true,
      suggest = {
        imports = {
          hosts = {
            ["https://deno.land"] = true,
          },
        },
      },
      config = "deno.json",
    },
  },
  -- Enable organize imports capability for Deno
  commands = {
    DenolsCache = {
      function()
        local clients = vim.lsp.get_clients { bufnr = 0, name = 'denols' }
        if #clients > 0 then
          local params = {
            command = 'deno.cache',
            arguments = { {}, vim.uri_from_bufnr(0) },
          }
          clients[#clients]:request('workspace/executeCommand', params, function(err, _result, ctx)
            if err then
              local uri = ctx.params.arguments[2]
              vim.notify('Cache command failed for ' .. vim.uri_to_fname(uri), vim.log.levels.ERROR)
            end
          end, 0)
        end
      end,
      description = 'Cache a module and all of its dependencies.',
    },
  },
  on_attach = function(client, bufnr)
    -- Setup default on_attach for denols
    require("nvchad.configs.lspconfig").on_attach(client, bufnr)
    
    -- Enable organize imports for denols
    client.server_capabilities.code_action_provider = true
    client.server_capabilities.execute_command_provider = true
    
    -- Add cache command to buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'LspDenolsCache', function()
      local params = {
        command = 'deno.cache',
        arguments = { {}, vim.uri_from_bufnr(bufnr) },
      }
      client:request('workspace/executeCommand', params, function(err, _result, ctx)
        if err then
          local uri = ctx.params.arguments[2]
          vim.notify('Cache command failed for ' .. vim.uri_to_fname(uri), vim.log.levels.ERROR)
        end
      end)
    end, {
      desc = 'Cache a module and all of its dependencies.',
    })
  end,
})

-- Configure TypeScript to avoid conflicts with Deno
vim.lsp.config("ts_ls", {
  on_attach = function(client, bufnr)
    -- Stop tsserver if Deno project detected
    if vim.fn.filereadable("deno.json") == 1 or vim.fn.filereadable("deno.jsonc") == 1 then
      client:stop()
    end
  end,
})
