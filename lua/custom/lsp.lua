require("mason").setup()

local capabilities =
    require("blink.cmp").get_lsp_capabilities()

vim.diagnostic.config({
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
    style = "minimal",
    header = "",
    prefix = "",
  },
  underline = { severity = vim.diagnostic.severity.ERROR },
  virtual_text = {
    source = "if_many",
    spacing = 2,
  },
})

local servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
    capabilities = capabilities,
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        format = { defaultConfig = { indent_style = "space", indent_size = "2" } },
      },
    },
  },
  rust_analyzer = {
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        diagnostics = {
          enable = false,
        },
      },
    },
  },
  pyright = {
    capabilities = capabilities,
    settings = {
      ["python"] = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          useLibraryCodeForTypes = true,
        },
      },
    },
  },
}

local ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "clangd" }

for _, name in ipairs(ensure_installed) do
  if servers[name] then
    vim.lsp.config(name, servers[name])
  end
end

require("mason-lspconfig").setup({
  ensure_installed = ensure_installed,
  automatic_enable = true,
})

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
      if vim.fn.has("linux") == 1 then
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = args.buf,

          callback = function()
            vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
          end,
        })
      elseif vim.fn.has("win32") == 1 then
        map("gf", function()
          vim.lsp.buf.format({
            range =
                vim.lsp.util.make_range_params(nil, "utf-16").range
          })
        end, "[G]et selection [F]ormatted", "v")
      end
    end
  end,
})
