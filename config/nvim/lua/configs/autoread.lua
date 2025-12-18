-- Trigger `autoread` when files changes on disk
-- https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
-- https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode

-- Throttle mechanism for checktime
local last_checktime = 0
local THROTTLE_SECONDS = 5 -- 5 seconds throttle period

vim.api.nvim_create_autocmd(
  { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "VimResized", "ModeChanged", "CursorMoved" },
  {
    pattern = "*",
    callback = function()
      local now = os.time()
      -- Only check if throttle period has passed
      if now - last_checktime >= THROTTLE_SECONDS then
        if not (vim.fn.mode():match "\v(c|r.?|!|t)") and vim.fn.getcmdwintype() == "" then
          vim.cmd "checktime"
          last_checktime = now
        end
      else
        -- Debug: Show when checktime is being throttled
        -- print(string.format('checktime throttled (last call: %d seconds ago)', now - last_checktime))
      end
    end,
  }
)

-- Notification after file change
-- https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
  pattern = "*",
  command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None",
})

