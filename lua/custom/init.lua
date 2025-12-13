require("custom.remap")
require("custom.set")
require("custom.theme")
require("custom.lsp")
require("custom.telescope")
require("custom.conform")
require("custom.treesitter")
require("custom.markview")

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("HighlightYank", {}),
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})
