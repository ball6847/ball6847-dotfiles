require "nvchad.mappings"
--
-- add yours here

local map = vim.keymap.set

-- nvchad hijack ; from vanilla vim and I don't like it ;-)
-- map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- copilot accept suggession
local copilot_accept_key = vim.loop.os_uname().sysname == "Darwin" and "<D-l>" or "<C-l>"

map("i", copilot_accept_key, function()
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
map("n", "<F5>", ":checktime<CR>:LspRestart<CR>", { desc = "Reload file and restart LSP" })

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

-- replay macro in register q with F3 (so, start recording with `qq`)
map("n", "<F3>", "@q", { noremap = true, silent = true, desc = "Replay macro in register a" })

-- map Ctrl+Backspace to delete word backward
local delete_bw_key = vim.loop.os_uname().sysname == "Darwin" and "<D-BS>" or "<C-H>"
map("i", delete_bw_key, "<C-W>", { noremap = true, silent = true, desc = "Delete word at cursor backward" })

-- toggle nvim-tree width between 40 and 60
local function toggle_nvim_tree_width()
  local view = require "nvim-tree.view"
  local api = require "nvim-tree.api"

  -- Close nvim-tree if open
  if view.is_visible() then
    api.tree.close()
  end

  -- Update the width dynamically
  view.View.width = view.View.width == 30 and 40 or 30

  -- Reopen nvim-tree with the new width
  api.tree.open()
end

map("n", "<leader>tw", toggle_nvim_tree_width, { desc = "Toggle nvim-tree width" })

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
map("n", "<leader>ci", organize_imports, { desc = "Organize Imports" })

-- Close all buffers except nvim-tree
map("n", "<leader>ba", function()
  local api = require "nvim-tree.api"

  -- Close all buffers except nvim-tree
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local buf_name = vim.api.nvim_buf_get_name(bufnr)
    if vim.api.nvim_buf_is_loaded(bufnr) and not buf_name:match "NvimTree_" then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end

  -- Reopen nvim-tree if it was previously visible
  if not api.tree.is_visible() then
    api.tree.open()
  end
end, { desc = "Close all buffers except NvimTree" })

-- mapping for toggle zen mode
map("n", "<leader>z", function()
  require("zen-mode").toggle {
    window = {
      width = 0.70, -- width will be 85% of the editor width
    },
  }
end, { desc = "Toggle zen mode" })

map("n", "<leader>ts", function()
  if vim.opt.spell:get() then
    require("spellwarn").disable()
    vim.opt.spell = false
  else
    require("spellwarn").enable()
    vim.opt.spell = true
  end
end, { desc = "Toggle SpellWarn" })
