vim.keymap.set("n", "<leader>g", function()
	vim.fn.jobstart({ "git", "fetch", "--all", "--jobs=0" })
	vim.cmd.Git()
end, { desc = "Git" })
local function is_netrw()
	return vim.bo.filetype == "netrw" or vim.fn.isdirectory(vim.api.nvim_buf_get_name(0)) == 1
end

vim.keymap.set("n", "<leader>gl", function()
	if is_netrw() then
		vim.cmd("G log")
	else
		vim.cmd("G log -- " .. vim.fn.fnameescape(vim.fn.expand("%:p")))
	end
end, { desc = "Git Log (file)" })
vim.keymap.set("n", "<leader>gL", function()
	if is_netrw() then
		vim.cmd("G log --graph --oneline --decorate")
	else
		vim.cmd("G log --graph --oneline --decorate -- " .. vim.fn.fnameescape(vim.fn.expand("%:p")))
	end
end, { desc = "Git Log Graph (file)" })
vim.keymap.set("n", "<leader>gb", "<cmd>G blame<CR>", { desc = "Git Blame" })
vim.keymap.set("n", "<leader>gm", "<cmd>G submodule update --init --recursive<CR>", { desc = "Git Submodule Update" })
vim.keymap.set("n", "<leader>gd", function()
  local ft = vim.bo.filetype
  local commit
  if ft == "netrw" then
    vim.cmd("edit " .. vim.fn.expand("<cfile>"))
    commit = "HEAD"
  elseif ft == "fugitiveblame" or ft == "fugitive" or ft == "git" then
    commit = vim.fn.expand("<cword>")
    vim.cmd("close!")
  else
    local blame = vim.fn.system("git blame -L " .. vim.fn.line(".") .. "," .. vim.fn.line(".") .. " " .. vim.fn.expand("%"))
    commit = blame:match("^(%w+)")
  end
  vim.cmd("Gvdiffsplit " .. commit .. "~1")
end, { desc = "Git Diff Commit with Previous" })
