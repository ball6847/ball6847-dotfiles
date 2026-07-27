require "nvchad.options"

-- enable true color support
vim.opt.termguicolors = true
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

-- set .env filetype and disable LSP
vim.filetype.add({
  extension = {
    env = "env",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "env",
  callback = function()
    vim.b.lspenabled = false
  end,
})

-- Ensure termguicolors is enabled even after NvChad loads
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.opt.termguicolors = true
  end,
})

-- WORKAROUND: Neovim 0.12.4 has a bug where markdown treesitter highlighting
-- crashes with "attempt to call method 'range' (a nil value)" when code blocks
-- with language injection are present. Disable treesitter for markdown and use
-- regex-based syntax highlighting instead.
--
-- We override vim.treesitter.start to no-op for markdown, since NvChad's
-- FileType autocmd will try to start it.
local _ts_start = vim.treesitter.start
vim.treesitter.start = function(lang, opts)
  -- When called without args, it uses current buffer's filetype
  local buf = opts and opts.buf or 0
  local ft = vim.bo[buf].filetype
  if ft == "markdown" then
    return
  end
  return _ts_start(lang, opts)
end