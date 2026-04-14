if vim.fn.has("win32") ~= 1 then
	return
end

-- set
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.shell = "pwsh.exe"
vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
vim.opt.shellquote = '"'
vim.opt.shellxquote = ""

-- clangd LSP config (Windows/MSVC specific)
local capabilities = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)

vim.lsp.config["clangd"] = {
	cmd = {
		"clangd",
		"--background-index",
		-- "--header-insertion=never",
		"--completion-style=detailed",
		"--function-arg-placeholders=false",
		"--clang-tidy",
		-- "--query-driver=C:\\BuildTools\\VC\\Tools\\MSVC\\14.16.27023\\bin\\Hostx86\\x86\\cl.exe",
	},
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = { "compile_commands.json", ".clangd", ".git" },
	capabilities = capabilities,
}

require("custom.msbuilder")

-- Override format behavior: no format-on-save, <leader>f = format selection only
require("conform").setup({
	format_on_save = false,
})
vim.keymap.set("n", "<leader>f", function() end, { desc = "Disabled: use visual selection" })
vim.keymap.set("v", "<leader>f", function()
	require("conform").format({ bufnr = 0 })
end, { desc = "Format selection" })

-- Override <C-f>: on Linux this launches `tmux neww tmux-sessionizer`.
-- On Windows we use psmux + the PowerShell-based psmux-sessionizer.ps1
-- (linked into Documents\PowerShell by setup.bat). jobstart avoids the
-- quoting pitfalls of running `:silent !...` through the custom pwsh
-- shellcmdflag.
local sessionizer = vim.fn.expand("$USERPROFILE/Documents/PowerShell/psmux-sessionizer.ps1")
vim.keymap.set("n", "<C-f>", function()
	vim.fn.jobstart({ "psmux", "neww", "pwsh", "-NoLogo", "-NoProfile", "-File", sessionizer }, { detach = true })
end, { desc = "Open psmux sessionizer" })
