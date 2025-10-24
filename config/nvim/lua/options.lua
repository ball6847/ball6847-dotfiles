require "nvchad.options"

-- add yours here!
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 10
vim.opt.exrc = true
vim.opt.spell = false -- toggle using <leader>ts
vim.opt.spelllang = "en"
-- vim.opt.winborder = "rounded" -- this really helps for lsp hover (K) visibility as it add a border to floating windows, but this get conflicted with some plugins especially with telescope
vim.opt.clipboard = "unnamedplus"

-- configure diagnostics
vim.diagnostic.config {
  virtual_text = true,
}

-- set tab size to 4 for Go files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})
