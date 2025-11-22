local tsConfig = {
	ensure_installed = { "c", "rust", "bash", "cpp", "go", "lua", "query", "markdown", "markdown_inline" },
	sync_install = false,
	auto_install = true,
	ignore_install = {},
	indent = {
		enable = true,
	},
	highlight = {
		enable = true,
		disable = { "c", "rust" },
		additional_vim_regex_highlighting = false,
	},
}
require("nvim-treesitter.configs").setup(tsConfig)
