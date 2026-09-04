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
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})

telescope.load_extension("fzf")

local map = function(keys, func, desc, mode)
  mode = mode or "n"
  vim.keymap.set(mode, keys, func, { desc = "Telescope: " .. desc })
end

local function git_cwd()
  local file = vim.api.nvim_buf_get_name(0)
  local dir
  if vim.bo.filetype == "oil" then
    dir = require("oil").get_current_dir() or vim.fn.expand("%:p"):gsub("[/\\]$", "")
  elseif file:match("^fugitive://") then
    local git_dir = file:match("^fugitive://(.-)//") or vim.b.fugitive_repo
    dir = git_dir and
        vim.fn.systemlist("git --git-dir=" .. vim.fn.shellescape(git_dir) .. " rev-parse --show-toplevel")[1]
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

map("<leader>fo", builtin.buffers, "[F]ind [O]pend buffers")
map("<leader>ff", builtin.find_files, "[F]ind [F]iles")
map("<leader>fh", builtin.help_tags, "[F]ind [H]elp")
map("<leader>fr", builtin.lsp_references, "[F]ind [R]eferences")
map("<leader>fw", builtin.grep_string, "[F]ind [W]ord", { "n", "v" })
map("<leader>fb", builtin.current_buffer_fuzzy_find, "[F]ind in [B]uffer")
map("<leader>fa", function()
  builtin.find_files({ no_ignore = true, hidden = true })
end, "[F]ind [A]ll files (no .gitignore, include hidden)")
map("<leader>fk", builtin.keymaps, "Search Keymaps")

map("<leader>gb", function()
  builtin.git_branches({ cwd = git_cwd(), show_remote_tracking_branches = true })
end, "[G]it [B]ranches")

require("custom.multigrep").setup()
