local builtin = require("telescope.builtin")
local map = function(keys, func, desc, mode)
	mode = mode or "n"
	vim.keymap.set(mode, keys, func, { desc = "Telescope: " .. desc })
end
map("<leader>fb", builtin.buffers, "[Find] [B]uffers")
map("<leader>ff", builtin.find_files, "[F]ind [F]iles")
map("<leader>fg", builtin.live_grep, "[F]ind live [G]rep")
map("<leader>fh", builtin.help_tags, "[F]ind [H]elp tags")
map("<leader>fr", builtin.lsp_references, "[F]ind [R]eferences")
map("<leader>fw", builtin.grep_string, "[F]ind [W]ord", { "n", "v" })
