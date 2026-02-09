vim.g.gruvbox_material_background = "soft"
vim.g.gruvbox_material_better_performance = 1
vim.g.gruvbox_material_enable_italic = 1
vim.g.gruvbox_material_diagnostic_text_highlight = 1
vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
vim.g.gruvbox_material_sign_column_background = "none"
vim.cmd.colorscheme("gruvbox-material")

local groups = {
	"Normal",
	"NormalNC",
	"NormalFloat",
	"FloatBorder",
	"FloatTitle",
	"SignColumn",
	"EndOfBuffer",
	"Pmenu",
	"PmenuSel",
	"PmenuSbar",
	"PmenuThumb",
	"VertSplit",
	"WinSeparator",
}

for _, g in ipairs(groups) do
	vim.api.nvim_set_hl(0, g, { bg = "NONE" })
end
