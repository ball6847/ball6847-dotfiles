-- configure clipboard sharing between WSL and Windows
local clip = "/mnt/c/Windows/System32/clip.exe" -- Change this path if needed

if vim.fn.executable(clip) then
  local opts = {
    callback = function()
      if vim.v.event.operator ~= "y" then
        return
      end
      vim.fn.system(clip, vim.fn.getreg(0))
    end,
  }

  opts.group = vim.api.nvim_create_augroup("WSLYank", {})
  vim.api.nvim_create_autocmd("TextYankPost", { group = opts.group, callback = opts.callback })
end
