local cmp = require("blink.cmp")

cmp.build():pwait()
cmp.setup({
  keymap = { preset = "default" },
  completion = { documentation = { auto_show = false } },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      -- blink's default only shows buffer words when the LSP returns nothing;
      -- list them alongside LSP items instead.
      lsp = { fallbacks = {} },
    },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})
