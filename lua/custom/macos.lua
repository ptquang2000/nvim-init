if vim.fn.has("mac") ~= 1 then
  return
end

-- ── clangd LSP (Apple toolchain) ────────────────────────────────────────────
-- Mason's clangd doesn't know the macOS SDK, so without --query-driver it
-- finds no system headers (<vector>, <stdio.h>) and completes nothing but
-- buffer words. Letting it query Apple's clang supplies the SDK include paths.
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--completion-style=detailed",
    "--function-arg-placeholders=false",
    "--clang-tidy",
    "--query-driver=/usr/bin/clang*,/Library/Developer/CommandLineTools/usr/bin/clang*,/Applications/Xcode*.app/**/clang*",
  },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- ── Format on save (every LSP client) ───────────────────────────────────────
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
  callback = function(args)
    local clients = vim.lsp.get_clients({ id = args.data.client_id })
    local client = clients[1]

    if client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,

        callback = function()
          vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
        end,
      })
    end
  end,
})
