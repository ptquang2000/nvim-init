require("markview").setup({})

vim.api.nvim_create_autocmd("User", {
	pattern = "MarkviewAttach",
	callback = function(_)
		vim.keymap.set("n", "<leader>m", "<cmd>Markview<CR>")
		vim.keymap.set("n", "<leader>ms", "<cmd>Markview splitToggle<CR>")
	end,
})
