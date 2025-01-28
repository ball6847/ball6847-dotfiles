local cmp = require "cmp"

cmp.setup {
  mapping = {
    ["<Tab>"] = function(fallback)
      local copilot = require "copilot.suggestion"
      if copilot.is_visible() then
        copilot.accept()
      elseif cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    ["<S-Tab>"] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end,
  },
}
