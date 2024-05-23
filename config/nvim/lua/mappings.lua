require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- nvchad hijack ; from vanilla vim and I don't like it ;-)
-- map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
