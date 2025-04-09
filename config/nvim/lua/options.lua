require "nvchad.options"

-- add yours here!
vim.opt.number = true
vim.opt.relativenumber = true
-- vim.opt.scrolloff = 20
vim.opt.clipboard = "unnamedplus"
vim.opt.exrc = true
vim.opt.spell = false -- toggle using <leader>ts
vim.opt.spelllang = "en"
-- vim.opt.winborder = "rounded" -- this really helps for lsp hover (K) visibility as it add a border to floating windows, but this get conflicted with some plugins especially with telescope
--

-- configure diagnostics
vim.diagnostic.config {
  -- Use the default configuration
  virtual_lines = true,

  -- Alternatively, customize specific options
  -- virtual_lines = {
  --  -- Only show virtual line diagnostics for the current cursor line
  --  current_line = true,
  -- },
}
