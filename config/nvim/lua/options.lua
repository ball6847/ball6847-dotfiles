require "nvchad.options"

-- add yours here!
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 10
vim.opt.exrc = true
vim.opt.spell = false -- toggle using <leader>ts
vim.opt.spelllang = "en"
-- vim.opt.winborder = "rounded" -- this really helps for lsp hover (K) visibility as it add a border to floating windows, but this get conflicted with some plugins especially with telescope

-- configure clipboard for WSL
-- TODO: copy from opencode panel doesn't work well with WSL, even we need to use win32yank.exe (only the first line copied), we might need to fix this at opencode.nvim plugin side
if vim.fn.has "wsl" == 1 then
  vim.g.clipboard = {
    name = "WSLClipboard",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = true,
  }
else
  vim.opt.clipboard = "unnamedplus"
end

-- configure diagnostics
vim.diagnostic.config {
  virtual_text = true,
}
