if vim.fn.has("win32") ~= 1 then
	return
end

require("msvc").setup({
	default_settings = {
		arch = "x64",
		jobs = 4,
	},
})

vim.keymap.set("n", "<leader>m", "<cmd>Msvc<CR>", { desc = "Msvc: open buffer" })
vim.keymap.set("n", "<leader>ma", "<cmd>Msvc add<CR>", { desc = "Msvc: add solution" })
vim.keymap.set("n", "<leader>ml", "<cmd>Msvc log<CR>", { desc = "Msvc: build log" })
vim.keymap.set("n", "<leader>mx", "<cmd>Msvc cancel<CR>", { desc = "Msvc: cancel build" })
