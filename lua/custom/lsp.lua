require("mason").setup()

local cmp = require("cmp")
cmp.setup({
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
	}),
	completion = {
		completeopt = "menu,menuone,noinsert",
	},
	sources = { { name = "nvim_lsp" }, { name = "buffer" } },
})

local capabilities = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)

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

vim.lsp.config["lua_ls"] = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = { library = vim.api.nvim_get_runtime_file("", true) },
			format = { enable = true, defaultConfig = { indent_style = "space", indent_size = "2" } },
		},
	},
}

require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "gopls", "rust_analyzer", "clangd" },
	automatic_enable = true,
})
