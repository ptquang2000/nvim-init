if vim.fn.has("win32") ~= 1 then
	return
end

-- ── Editor options (Windows) ────────────────────────────────────────────────
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

vim.opt.shell = "pwsh.exe"
vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
vim.opt.shellquote = '"'
vim.opt.shellxquote = ""

-- ── clangd LSP (MSVC toolchain) ─────────────────────────────────────────────
vim.lsp.config["clangd"] = {
	cmd = {
		"clangd",
		"--background-index",
		"--completion-style=detailed",
		"--function-arg-placeholders=false",
		"--clang-tidy",
		"--compile-commands-dir=./bin",
		"--query-driver=C:/Program Files/Microsoft Visual Studio/**/cl.exe",
	},
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = { "compile_commands.json", ".clangd", ".git" },
	capabilities = vim.tbl_deep_extend(
		"force",
		{},
		vim.lsp.protocol.make_client_capabilities(),
		require("cmp_nvim_lsp").default_capabilities()
	),
}

-- ── nvim-msvc (Windows-only; registered here so it's not pulled on other OSes)
vim.pack.add({
	{ src = "https://github.com/ptquang2000/nvim-msvc.git" },
})
require("custom.msvc")

-- ── conform.nvim: format on selection only ──────────────────────────────────
require("conform").setup({ format_on_save = false })
vim.keymap.set("n", "<leader>f", function() end, { desc = "Disabled: use visual selection" })
vim.keymap.set("v", "<leader>f", function()
	require("conform").format({ bufnr = 0 })
end, { desc = "Format selection" })

-- ── <C-f>: psmux-sessionizer (Windows replacement for tmux-sessionizer) ────
local sessionizer = vim.fn.expand("$USERPROFILE/Documents/PowerShell/psmux-sessionizer.ps1")
vim.keymap.set("n", "<C-f>", function()
	vim.fn.jobstart({ "psmux", "neww", "pwsh", "-NoLogo", "-NoProfile", "-File", sessionizer }, { detach = true })
end, { desc = "Open psmux sessionizer" })
