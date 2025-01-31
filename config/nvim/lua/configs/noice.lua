-- TODO: nvchad already has default handler for lsp signature and hover,
-- so we don't have any chance to try out lsp signature and hover handler.
-- but we will do some day
require("noice").setup {
  lsp = {
    signature = {
      enabled = false,
    },
    hover = {
      enabled = false,
    },
  },
  --
  routes = {
    {
      view = "notify",
      filter = { event = "msg_showmode" },
    },
  },
}
