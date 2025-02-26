-- configure cmp-cmdline, https://github.com/hrsh7th/cmp-cmdline

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

cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    {
      name = "cmdline",
      option = {
        ignore_cmds = { "Man", "!" },
      },
    },
  }),
})
