if vim.fn.has("linux") ~= 1 then
	return
end

vim.pack.add({
	{ src = "https://github.com/mfussenegger/nvim-dap.git" },
	{ src = "https://github.com/nvim-neotest/nvim-nio.git" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui.git" },
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text.git" },
})

require("custom.dap")

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
