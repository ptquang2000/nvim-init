local cmp = require("blink.cmp")

cmp.build():pwait()
cmp.setup({
  keymap = { preset = "default" },
  completion = { documentation = { auto_show = false } },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})
