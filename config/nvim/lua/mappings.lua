require "nvchad.mappings"
--
-- add yours here

local map = vim.keymap.set

-- nvchad hijack ; from vanilla vim and I don't like it ;-)
-- map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- copilot accept suggession
local copilot_accept_key = vim.loop.os_uname().sysname == "Darwin" and "<A-l>" or "<C-l>"

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

-- replay macro in register q with F4 (so, start recording with `qq`)
map("n", "<F4>", "@q", { noremap = true, silent = true, desc = "Replay macro in register q" })

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

-- Only register Alt+Shift mappings on macOS
if vim.loop.os_uname().sysname == "Darwin" then
  map("n", "<A-S-J>", "10jzz", { noremap = true, silent = true, desc = "Move next 20 lines" })
  map("n", "<A-S-K>", "10kzz", { noremap = true, silent = true, desc = "Move prev 20 lines" })
end

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

-- Shift+ESC to exit terminal mode
local function exit_terminal_mode()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), "n", true)
end

-- Map Shift+Esc in terminal mode
vim.keymap.set("t", "<S-Esc>", exit_terminal_mode, { desc = "Shift+Esc to exit terminal mode" })

-- Map Shift+Esc in insert mode to exit insert mode
vim.keymap.set("i", "<S-Esc>", "<Esc>", { desc = "Shift+Esc to exit insert mode" })

-- Shift+arrow key navigation for windows (exits terminal mode first)
vim.keymap.set("t", "<S-Left>", function()
  vim.cmd "stopinsert"
  vim.cmd "wincmd h"
end, { desc = "Navigate to left window" })

vim.keymap.set("t", "<S-Right>", function()
  vim.cmd "stopinsert"
  vim.cmd "wincmd l"
end, { desc = "Navigate to right window" })

vim.keymap.set("t", "<S-Up>", function()
  vim.cmd "stopinsert"
  vim.cmd "wincmd k"
end, { desc = "Navigate to upper window" })

vim.keymap.set("t", "<S-Down>", function()
  vim.cmd "stopinsert"
  vim.cmd "wincmd j"
end, { desc = "Navigate to lower window" })

-- Also enable shift+arrow navigation in normal mode
vim.keymap.set("n", "<S-Left>", "<C-w>h", { desc = "Navigate to left window" })
vim.keymap.set("n", "<S-Right>", "<C-w>l", { desc = "Navigate to right window" })
vim.keymap.set("n", "<S-Up>", "<C-w>k", { desc = "Navigate to upper window" })
vim.keymap.set("n", "<S-Down>", "<C-w>j", { desc = "Navigate to lower window" })

-- For opencode.nvim keymappings please check https://github.com/NickvanDyke/opencode.nvim?tab=readme-ov-file#-setup
-- Opencode keymaps (moved from plugin config for better organization)
map({ "n", "x" }, "<leader>oa", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Ask about this" })

map({ "n", "x" }, "<leader>os", function()
  require("opencode").select()
end, { desc = "Select prompt" })

map({ "n", "x" }, "<leader>o+", function()
  require("opencode").prompt "@this"
end, { desc = "Add this" })

map("n", "<leader>ot", function()
  require("opencode").toggle()
end, { desc = "Toggle embedded" })

map("n", "<leader>oc", function()
  require("opencode").command()
end, { desc = "Select command" })

map("n", "<leader>on", function()
  require("opencode").command "session_new"
end, { desc = "New session" })

map("n", "<leader>oi", function()
  require("opencode").command "session_interrupt"
end, { desc = "Interrupt session" })

map("n", "<leader>oA", function()
  require("opencode").command "agent_cycle"
end, { desc = "Cycle selected agent" })

map("n", "<S-C-u>", function()
  require("opencode").command "messages_half_page_up"
end, { desc = "Messages half page up" })

map("n", "<S-C-d>", function()
  require("opencode").command "messages_half_page_down"
end, { desc = "Messages half page down" })

-- Remap Ctrl+W to <leader>w for window operations
-- Also support Cmd+W on Mac
map("n", "<leader>w", "<C-w>", { noremap = true, silent = true, desc = "Window operations prefix" })

-- nvim-scrollbar keybindings
map("n", "<leader>sc", function()
  require("scrollbar").clear()
end, { desc = "Clear scrollbar marks" })

-- Terminal toggle mappings are now handled in the plugin configuration itself
