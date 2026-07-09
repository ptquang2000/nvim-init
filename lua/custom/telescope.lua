local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
	defaults = {
		layout_strategy = "bottom_pane",
		layout_config = {
			height = 25,
			prompt_position = "top",
		},
	},
})

local map = function(keys, func, desc, mode)
	mode = mode or "n"
	vim.keymap.set(mode, keys, func, { desc = "Telescope: " .. desc })
end

local function git_cwd()
	local file = vim.api.nvim_buf_get_name(0)
	local dir
	if vim.bo.filetype == "netrw" then
		dir = vim.b.netrw_curdir or vim.fn.expand("%:p"):gsub("[/\\]$", "")
	elseif file:match("^fugitive://") then
		local git_dir = file:match("^fugitive://(.-)//") or vim.b.fugitive_repo
		dir = git_dir and vim.fn.systemlist("git --git-dir=" .. vim.fn.shellescape(git_dir) .. " rev-parse --show-toplevel")[1]
		dir = dir or vim.fn.getcwd()
	elseif vim.fn.isdirectory(file) == 1 then
		dir = file:gsub("[/\\]$", "")
	elseif file ~= "" then
		dir = vim.fn.fnamemodify(file, ":h")
	else
		dir = vim.fn.getcwd()
	end
	local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel")[1]
	return (git_root and git_root ~= "") and git_root or dir
end

map("<leader>sb", builtin.buffers, "Search Buffers")
map("<leader>sf", builtin.find_files, "Search Files")
map("<leader>sg", builtin.live_grep, "Search Grep")
map("<leader>sh", builtin.help_tags, "Search Help")
map("<leader>sr", builtin.lsp_references, "Search References")
map("<leader>sw", builtin.grep_string, "Search Word", { "n", "v" })
map("<leader>ss", builtin.current_buffer_fuzzy_find, "Search in Buffer")
map("<leader>si", function()
	builtin.find_files({ no_ignore = true, hidden = true })
end, "Search Files (no .gitignore, incl hidden)")
map("<leader>sk", builtin.keymaps, "Search Keymaps")

map("<leader>sG", function()
	builtin.git_files({ cwd = git_cwd() })
end, "Search Git Files")
map("<leader>g", function()
	builtin.git_status({ cwd = git_cwd() })
end, "Git Status")
map("<leader>gS", function()
	builtin.git_stash({ cwd = git_cwd() })
end, "Git Stash")
map("<leader>gB", function()
	builtin.git_branches({ cwd = git_cwd(), show_remote_tracking_branches = true })
end, "Git Branches")
