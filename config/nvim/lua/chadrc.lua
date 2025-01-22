-- This file  needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
  nvdash = {
    load_on_startup = true,
  },

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

M.base46 = {
  theme = "doomchad",
  transparent = false,
  hl_add = {},
  hl_override = {},
  integrations = {},
  theme_toggle = { "doomchad", "one_light" },
}

return M
