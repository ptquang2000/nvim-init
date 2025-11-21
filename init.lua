vim.pack.add({
	{ src = "https://github.com/sainnhe/gruvbox-material.git" },

	{ src = "https://github.com/stevearc/conform.nvim.git" },

	{ src = "https://github.com/neovim/nvim-lspconfig.git" },
	{ src = "https://github.com/mason-org/mason.nvim.git" },
	{ src = "https://github.com/hrsh7th/nvim-cmp.git" },
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp.git" },

	{ src = "https://github.com/nvim-lua/plenary.nvim.git" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim.git" },
})
require("custom")
