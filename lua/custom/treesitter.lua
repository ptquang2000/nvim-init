local treesitter = require("nvim-treesitter")
treesitter.setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})
treesitter.install({
	"c",
	"rust",
	"bash",
	"cpp",
	"go",
	"lua",
	"query",
	"markdown",
	"markdown_inline",
	"latex",
})
