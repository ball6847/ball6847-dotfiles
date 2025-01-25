require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- nvchad hijack ; from vanilla vim and I don't like it ;-)
-- map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- copilot accept suggession
map("i", "<C-l>", function()
  vim.fn.feedkeys(vim.fn["copilot#Accept"](), "")
end, {
  replace_keycodes = true,
  nowait = true,
  silent = true,
  expr = true,
  noremap = true,
})

-- keep visual mode after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- if buffer doesn't get updated after saving externally, use F5 to reload
map("n", "<F5>", ":checktime<CR>", { desc = "Reload file" })
map("n", "<F6>", ":%s/\\r/\\r/g<CR>", { desc = "Remove ^M" })

-- mapping spectre
map("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', {
  desc = "Toggle Spectre",
})
map("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
  desc = "Search current word",
})
map("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
  desc = "Search current word",
})
map("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
  desc = "Search on current file",
})

-- organize imports
local function organize_imports()
  local params = vim.lsp.util.make_range_params()
  params.context = { only = { "source.organizeImports" } }

  local clients = vim.lsp.get_active_clients()
  for _, client in pairs(clients) do
    if client.supports_method "textDocument/codeAction" then
      client.request("textDocument/codeAction", params, function(err, res)
        if err then
          vim.notify("Error organizing imports: " .. err.message, vim.log.levels.ERROR)
          return
        end

        if res and res[1] then
          local action = res[1]

          -- If the action has an `edit` field, apply it
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
          end

          -- If the action has a `command` field, execute it
          if action.command then
            vim.lsp.buf.execute_command(action.command)
          end
        else
          vim.notify("No organize imports action available", vim.log.levels.INFO)
        end
      end)
      return
    end
  end
end

-- Mapping to trigger the function
vim.keymap.set("n", "<leader>cai", organize_imports, { desc = "Organize Imports" })
