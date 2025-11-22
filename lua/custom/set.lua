-- line
vim.o.nu = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true

-- indent
vim.o.smartindent = true
vim.o.breakindent = true

-- searching
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = false

-- visual
vim.o.colorcolumn = "80"
vim.o.wrap = false
vim.o.termguicolors = true
vim.o.signcolumn = "yes"
vim.o.scrolloff = 8
vim.o.winborder = "rounded"

-- file
vim.o.swapfile = false
vim.o.backup = false
vim.o.autoread = true
vim.o.undofile = true

-- completion
vim.o.completeopt = ""
vim.o.complete = ""

-- misc
vim.o.confirm = true
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)
