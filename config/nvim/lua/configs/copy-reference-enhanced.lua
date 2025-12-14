-- Enhanced copy-reference functionality that includes selected text
--
-- This module provides standalone copy-reference functionality that includes selected text content
-- along with file references. It no longer depends on copy-reference.nvim plugin.
--
-- Features:
-- - Smart path detection (git root relative paths)
-- - Copies file paths and line numbers (e.g., "file.lua:10-15")
-- - Adds actual code content in a properly formatted markdown code block
local M = {}

-- Get relative path
local function get_relative_path()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return "unnamed"
  end

  -- Try to get path relative to git root
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if git_root ~= "" and bufname:find(git_root, 1, true) then
    return bufname:sub(#git_root + 2)
  end

  -- Fallback to current working directory
  local cwd = vim.fn.getcwd()
  if bufname:find(cwd, 1, true) then
    return bufname:sub(#cwd + 2)
  end

  -- Return full path if not relative to git root or cwd
  return bufname
end

-- Copy reference with text content
function M.copy_reference_with_text()
  local mode = vim.api.nvim_get_mode().mode

  -- Get file path
  local path = get_relative_path()

  local start_line, end_line, text_lines

  if mode:match "^[vV\022]" then
    -- Visual mode: get selected range and text
    local l1 = vim.fn.line "v"
    local l2 = vim.fn.line "."
    start_line = math.min(l1, l2)
    end_line = math.max(l1, l2)

    -- Get the actual text content
    text_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  else
    -- Normal mode: get current line and text
    start_line = vim.fn.line "."
    end_line = start_line
    text_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)
  end

  -- Build the reference string
  local reference
  if start_line == end_line then
    reference = path .. ":" .. start_line
  else
    reference = path .. ":" .. start_line .. "-" .. end_line
  end

  -- Get filetype for syntax highlighting hint
  local filetype = vim.bo.filetype

  -- Build the final content
  local content = reference .. "\n"
  if filetype and filetype ~= "" then
    content = content .. "```" .. filetype .. "\n"
  else
    content = content .. "```\n"
  end

  -- Add the text content
  for _, line in ipairs(text_lines) do
    content = content .. line .. "\n"
  end

  content = content .. "```"

  -- Copy to clipboard
  vim.fn.setreg("+", content)

  -- Notify user
  local line_range = start_line == end_line and "line " .. start_line or "lines " .. start_line .. "-" .. end_line
  vim.notify("Copied " .. line_range .. " with reference to clipboard", vim.log.levels.INFO)

  -- Return the content for potential further use
  return content
end

-- Copy file reference only
function M.copy_reference()
  local path = get_relative_path()
  local start_line = vim.fn.line "."
  local reference = path .. ":" .. start_line
  vim.fn.setreg("+", reference)
  vim.notify("Copied reference to clipboard", vim.log.levels.INFO)
end

-- Copy file path only
function M.copy_filename()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    vim.notify("No file name to copy", vim.log.levels.WARN)
    return
  end

  -- Get relative path (same as copy_reference_only but without line numbers)
  local path = get_relative_path()
  vim.fn.setreg("+", path)
  vim.notify("Copied file path to clipboard", vim.log.levels.INFO)
end

return M
