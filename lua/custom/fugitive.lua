vim.keymap.set("n", "<leader>G", function()
	vim.cmd.Git()
	vim.schedule(function()
		vim.api.nvim_feedkeys(":Git fetch --all --jobs=0", "n", false)
	end)
end, { desc = "[G]it Fetch" })
local function is_netrw()
	return vim.bo.filetype == "netrw" or vim.fn.isdirectory(vim.api.nvim_buf_get_name(0)) == 1
end

vim.keymap.set("n", "<leader>gL", function()
	if is_netrw() then
		vim.cmd("G log")
	else
		vim.cmd("G log -- " .. vim.fn.fnameescape(vim.fn.expand("%:p")))
	end
end, { desc = "[G]it [L]og" })
vim.keymap.set("n", "<leader>gl", function()
	if is_netrw() then
		vim.cmd("G log --graph --oneline --decorate")
	else
		vim.cmd("G log --graph --oneline --decorate -- " .. vim.fn.fnameescape(vim.fn.expand("%:p")))
	end
end, { desc = "[G]it [l]og Graph" })
vim.keymap.set("n", "<leader>gb", "<cmd>G blame<CR>", { desc = "[G]it [B]lame" })
vim.keymap.set("n", "<leader>gm", function()
	local root = vim.fn.FugitiveWorkTree()
	if root == "" then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return
	end
	local parent = vim.fn
		.system("git -C " .. vim.fn.shellescape(root) .. " rev-parse --show-superproject-working-tree")
		:gsub("\n", "")
	if parent ~= "" then
		vim.api.nvim_feedkeys(
			":Gcd " .. vim.fn.fnameescape(parent) .. " | Git submodule update --init --recursive",
			"n",
			false
		)
	else
		vim.api.nvim_feedkeys(":Git submodule update --init --recursive", "n", false)
	end
end, { desc = "[G]it [S]ubmodule Update" })
vim.keymap.set("n", "<leader>gd", function()
	local ft = vim.bo.filetype
	local prev, commit
	if ft == "fugitiveblame" or ft == "fugitive" or ft == "git" then
		commit = vim.fn.expand("<cword>")
		vim.cmd("close!")
		prev = commit .. "~1"
	else
		prev = "HEAD"
		commit = "."
	end
	if not is_netrw() then
		vim.cmd("Gvdiffsplit " .. prev)
		return
	end
	local git_root = vim.fn.FugitiveWorkTree()
	if git_root == "" then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return
	end
	local result = vim.fn.FugitiveExecute({ "diff", "--name-only", prev, commit })
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
end, { desc = "[G]it [D]iff Commit with Previous" })
