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
	local commit = "HEAD"
	if ft == "fugitiveblame" or ft == "fugitive" or ft == "git" then
		commit = vim.fn.expand("<cword>")
		vim.cmd("close!")
	end
	if not is_netrw() then
		vim.cmd("Gvdiffsplit " .. commit .. "~1")
		return
	end
	local git_root = vim.fn.FugitiveWorkTree()
	if git_root == "" then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return
	end
	local result = vim.fn.FugitiveExecute({ "diff", "--name-only", commit .. "~1", commit })
	if result.exit_status ~= 0 or #result.stdout == 0 then
		vim.notify("No changed files found", vim.log.levels.INFO)
		return
	end
	local qflist = {}
	for _, fname in ipairs(result.stdout) do
		if fname ~= "" then
			table.insert(qflist, { filename = git_root .. "/" .. fname, text = "changed in " .. commit })
		end
	end
	vim.fn.setqflist(qflist, "r")
	vim.cmd("copen")
end, { desc = "Git Diff Commit with Previous" })
