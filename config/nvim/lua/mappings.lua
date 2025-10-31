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
  -- TODO: we might need to provide different codeAction name based on specific lsp
  params.context = {
    only = {
      "source.organizeImports",
    },
  }

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

-- move lines up and down
-- not sure why, but in mac os, we need cmd+shift+j or cmd+shift+k to move lines (linux works fine with ctrl+j or ctrl+k)
map("n", "<" .. vim.g.os_ctrl_key .. "-J>", "10jzz", { noremap = true, silent = true, desc = "Move next 20 lines" })
map("n", "<" .. vim.g.os_ctrl_key .. "-K>", "10kzz", { noremap = true, silent = true, desc = "Move prev 20 lines" })

-- show VGit project diff preview
map("n", "<leader>df", "<cmd>VGit project_diff_preview<CR>", { desc = "Show VGit project diff preview" })

-- telescope - find function or method
map("n", "<leader>fn", function()
  require("telescope.builtin").lsp_document_symbols {
    symbols = { "function", "method" },
    symbol_width = 100,
  }
end, { desc = "Find function or method" })

map("n", "<leader>tr", ":TestNearest -v<CR>", { noremap = true, silent = true, desc = "Run test nearest" })
map("n", "<leader>tf", ":TestFile -v<CR>", { noremap = true, silent = true, desc = "Run test file" })
map("n", "<leader>ts", ":TestSuite<CR>", { noremap = true, silent = true, desc = "Run test suite" })
map("n", "<leader>tt", ":TestLast<CR>", { noremap = true, silent = true, desc = "Run last test" })
map("n", "<leader>tv", ":TestVisit<CR>", { noremap = true, silent = true, desc = "Visit test file" })

-- Double ESC to exit terminal mode
local last_esc_time = 0
local esc_timer = vim.loop.new_timer()

local function double_esc()
  local current_time = vim.loop.hrtime()
  if current_time - last_esc_time < 500000000 then -- 500ms
    esc_timer:stop()
    last_esc_time = 0
    -- Exit terminal mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), "n", true)
  else
    last_esc_time = current_time
    esc_timer:start(500, 0, function()
      last_esc_time = 0
    end)
  end
end

-- Map double Esc in terminal mode
vim.keymap.set("t", "<Esc>", double_esc, { desc = "Double Esc to exit terminal mode" })

-- For opencode.nvim keymappings please check https://github.com/NickvanDyke/opencode.nvim?tab=readme-ov-file#-setup

-- Remap Ctrl+W to <leader>w for window operations
map("n", "<leader>w", "<C-w>", { noremap = true, silent = true, desc = "Window operations prefix" })
