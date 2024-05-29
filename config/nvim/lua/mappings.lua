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
