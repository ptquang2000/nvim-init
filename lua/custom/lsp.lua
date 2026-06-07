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

vim.lsp.config["rust_analyzer"] = {
	settings = {
		["rust-analyzer"] = {
			diagnostics = {
				enable = false,
			},
		},
	},
}

vim.lsp.config["pyright"] = {
	settings = {
		["python"] = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "openFilesOnly",
				useLibraryCodeForTypes = true,
			},
		},
	},
}

require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "gopls", "rust_analyzer", "clangd", "pyright" },
	automatic_enable = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("custom-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end
		map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
		map("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
		map("gy", vim.lsp.buf.type_definition, "[G]oto t[Y]pe definition")
		map("K", vim.lsp.buf.hover, "[H]over documentation")
		map("gs", vim.lsp.buf.signature_help, "[S]ignature help", { "n", "i" })
		map("gR", vim.lsp.buf.references, "[R]eferences")
		map("grn", vim.lsp.buf.rename, "[R]e[N]ame symbol")
		map("ga", vim.lsp.buf.code_action, "Code [A]ction", { "n", "v" })
		map("gci", vim.lsp.buf.incoming_calls, "[I]ncoming calls")
		map("gco", vim.lsp.buf.outgoing_calls, "[O]utgoing calls")
	end,
})
