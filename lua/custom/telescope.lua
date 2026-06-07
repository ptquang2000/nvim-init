local builtin = require("telescope.builtin")
local map = function(keys, func, desc, mode)
	mode = mode or "n"
	vim.keymap.set(mode, keys, func, { desc = "Telescope: " .. desc })
end
map("<leader>sb", builtin.buffers, "Search Buffers")
map("<leader>sf", builtin.find_files, "Search Files")
map("<leader>sg", builtin.live_grep, "Search Grep")
map("<leader>sh", builtin.help_tags, "Search Help")
map("<leader>sr", builtin.lsp_references, "Search References")
map("<leader>sw", builtin.grep_string, "Search Word", { "n", "v" })
map("<leader>ss", builtin.current_buffer_fuzzy_find, "Search in Buffer")
map("<leader>si", function() builtin.find_files({ no_ignore = true }) end, "Search Files (no .gitignore)")
