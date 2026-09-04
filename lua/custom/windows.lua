if vim.fn.has("win32") ~= 1 then
  return
end

-- ── Editor options (Windows) ────────────────────────────────────────────────
vim.o.shell = "pwsh.exe"
vim.o.shellcmdflag =
"-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
vim.o.shellpipe = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'
vim.o.shellquote = ""
vim.o.shellxquote = ""

-- ── clangd LSP (MSVC toolchain) ─────────────────────────────────────────────
vim.lsp.config["clangd"] = {
  cmd = {
    "clangd",
    "--background-index",
    "--completion-style=detailed",
    "--function-arg-placeholders=false",
    "--clang-tidy",
    "--query-driver=C:/Program Files/Microsoft Visual Studio/**/cl.exe",
  },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = { "compile_commands.json", ".clangd", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities()
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
  callback = function(args)
    local clients = vim.lsp.get_clients({ id = args.data.client_id })
    local client = clients[1]

    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
    end

    if client:supports_method("textDocument/formatting") then
      map("gf", function()
        vim.lsp.buf.format({
          range =
              vim.lsp.util.make_range_params(nil, "utf-16").range
        })
      end, "[G]et selection [F]ormatted", "v")
    end
  end,
})

-- ── nvim-msvc
vim.pack.add({
  { src = "https://github.com/ptquang2000/nvim-msvc.git" },
})
-- vim.opt.runtimepath:prepend("C:/Users/quang.phan/work/nvim-msvc")
require("custom.msvc")

-- ── <C-f>: psmux-sessionizer (Windows replacement for tmux-sessionizer) ────
vim.keymap.set("n", "<C-f>", function()
  vim.fn.jobstart({
    "psmux",
    "display-popup",
    "-w",
    "80%",
    "-h",
    "70%",
    "-E",
    "pwsh",
    "-NoProfile",
    "-File",
    vim.fn.expand("$USERPROFILE") .. "/Documents/PowerShell/psmux-sessionizer.ps1",
  })
end, { desc = "Open psmux sessionizer" })
