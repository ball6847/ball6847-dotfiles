-- Auto-close quickfix when leaving it
-- This will automatically close the quickfix/location list when you select an entry
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    if buftype == "quickfix" then
      -- Schedule the close to avoid conflicts
      vim.schedule(function()
        local wins = vim.api.nvim_list_wins()
        for _, win in ipairs(wins) do
          if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
            -- Only close if we're not in the quickfix window anymore
            if vim.api.nvim_get_current_win() ~= win then
              vim.api.nvim_win_close(win, true)
            end
          end
        end
      end)
    end
  end,
})
