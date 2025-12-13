-- Enhanced copy-reference functionality that includes selected text
--
-- This module extends the functionality of copy-reference.nvim plugin to support copying
-- selected text content along with file references. The original plugin only copies file
-- paths and line numbers (e.g., "file.lua:10-15"), but this enhancement adds the actual
-- code content in a properly formatted markdown code block.
--
-- Integration with copy-reference.nvim:
-- - Leverages the plugin's smart path detection (git root relative paths)
-- - Maintains compatibility with existing keybindings (yr/yrr)
-- - Adds new functionality: Shift+Y in visual mode for instant copy of selection + reference
--
-- Usage:
-- - Visual mode: Select text → Shift+Y → copies formatted code with file reference
-- - Normal mode: <leader>cL → copies current line with reference
-- Output format:
--   path/to/file.lua:10-15
--   ```lua
--   function example() {
--       // selected code
--   }
--   ```
--
-- This enhancement bridges the gap between simple file references and complete code context,
-- making it ideal for sharing precise code locations with accompanying content in AI-assisted (kimi-for-coding)
-- development workflows.
local M = {}

-- Get relative path (similar to copy-reference plugin)
local function get_relative_path()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return "unnamed"
  end

  -- Try to get path relative to git root
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if git_root ~= "" and bufname:find(git_root, 1, true) then
    return bufname:sub(#git_root + 2) -- +2 to remove the slash
  end

  -- Fallback to current working directory
  local cwd = vim.fn.getcwd()
  if bufname:find(cwd, 1, true) then
    return bufname:sub(#cwd + 2)
  end

  -- Return full path if not relative to git root or cwd
  return bufname
end

-- Enhanced copy function that includes text content
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
  vim.fn.setreg("1", content) -- Also copy to register 1 as backup

  -- Notify user
  local line_range = start_line == end_line and "line " .. start_line or "lines " .. start_line .. "-" .. end_line
  vim.notify("Copied " .. line_range .. " with reference to clipboard", vim.log.levels.INFO)
end

-- Simple copy reference (file:line) without text
function M.copy_reference_only()
  vim.cmd "CopyReference line"
end

-- Copy only the selected text without reference
function M.copy_text_only()
  local mode = vim.api.nvim_get_mode().mode

  if not mode:match "^[vV\022]" then
    vim.notify("Please select text in visual mode", vim.log.levels.WARN)
    return
  end

  -- Use normal yank behavior
  vim.cmd "normal! y"
  vim.notify("Copied selected text", vim.log.levels.INFO)
end

return M
