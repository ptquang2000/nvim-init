vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "[<Esc>] Clear search highlights" })
vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "[E]xplorer" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "[<C-d>] Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "[<C-u>] Scroll up and center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "[N]ext search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "[N]ext search result (backwards)" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "[J]oin lines (keep cursor)" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "[J] Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "[K] Move selection up" })

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "[P]aste without yanking" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "[Y]ank to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "[Y]ank to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "[D]elete to black hole register" })

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open tmux sessionizer" })
