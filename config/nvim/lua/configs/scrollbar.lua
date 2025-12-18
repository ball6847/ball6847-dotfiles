-- Custom scrollbar highlights for better visibility
local highlights = {
  -- Make the scrollbar handle more visible
  ScrollbarHandle = { fg = "#666666", bg = "#333333" },
  ScrollbarCursorHandle = { fg = "#ffffff", bg = "#555555" },

  -- Make error/warning marks more visible
  ScrollbarError = { fg = "#ff5555", bg = "#ff5555" },
  ScrollbarErrorHandle = { fg = "#ff5555", bg = "#ff5555" },
  ScrollbarWarn = { fg = "#ffaa55", bg = "#ffaa55" },
  ScrollbarWarnHandle = { fg = "#ffaa55", bg = "#ffaa55" },

  -- Make search marks more visible
  ScrollbarSearch = { fg = "#55ff55", bg = "#55ff55" },
  ScrollbarSearchHandle = { fg = "#55ff55", bg = "#55ff55" },

  -- Make git marks more visible
  ScrollbarGitAdd = { fg = "#55ff55", bg = "#55ff55" },
  ScrollbarGitAddHandle = { fg = "#55ff55", bg = "#55ff55" },
  ScrollbarGitChange = { fg = "#ffaa55", bg = "#ffaa55" },
  ScrollbarGitChangeHandle = { fg = "#ffaa55", bg = "#ffaa55" },
  ScrollbarGitDelete = { fg = "#ff5555", bg = "#ff5555" },
  ScrollbarGitDeleteHandle = { fg = "#ff5555", bg = "#ff5555" },
}

-- Apply the highlights
for group, colors in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, colors)
end

