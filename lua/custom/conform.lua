require("conform").setup({
	opts = {},
	format_on_save = {
		timeout_ms = 5000,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "gofmt" },
		python = { "black", "isort" },
	},
	formatters = {},
})

vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ bufnr = 0 })
end, { desc = "[F]ormat buffer" })
