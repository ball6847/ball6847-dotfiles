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
  -- routing vim messages
  routes = {
    -- message like @q for macro recording to show in notification, or we won't see it anywhere
    {
      view = "notify",
      filter = { event = "msg_showmode" },
    },
    -- skip buffer write notification, as the notificatoin could block our code
    {
      filter = {
        event = "msg_show",
        kind = "",
        find = "written",
      },
      opts = { skip = true },
    },
  },
}
