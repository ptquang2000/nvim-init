require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})
require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
	sync_install = false,
	auto_install = true,
	ignore_install = { "javascript" },
	highlight = {
		enable = true,
		disable = { "c", "rust" },
		additional_vim_regex_highlighting = false,
	},
})
