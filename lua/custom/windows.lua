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
-- vim.opt.runtimepath:prepend("C:/Users/quang.phan/work/nvim-msvc")
require("custom.msvc")

-- ── conform.nvim: format on selection only for C/C++ filetypes ─────────────
local cpp_ft = { c = true, cpp = true, objc = true, objcpp = true }
require("conform").setup({
	format_on_save = function(bufnr)
		if cpp_ft[vim.bo[bufnr].filetype] then
			return nil
		end
		return { timeout_ms = 5000, lsp_format = "fallback" }
	end,
})
vim.keymap.set("n", "<leader>f", function()
	if cpp_ft[vim.bo[0].filetype] then
		vim.notify("Full-file format disabled for C/C++; use visual selection", vim.log.levels.INFO)
		return
	end
	require("conform").format({ bufnr = 0 })
end, { desc = "Format buffer (disabled for C/C++)" })
vim.keymap.set("v", "<leader>f", function()
	require("conform").format({ bufnr = 0 })
end, { desc = "Format selection" })

-- ── <C-f>: psmux-sessionizer (Windows replacement for tmux-sessionizer) ────
local sessionizer = vim.fn.expand("$USERPROFILE/Documents/PowerShell/psmux-sessionizer.ps1")
vim.keymap.set("n", "<C-f>", function()
	vim.fn.jobstart({ "psmux", "neww", "pwsh", "-NoLogo", "-NoProfile", "-File", sessionizer }, { detach = true })
end, { desc = "Open psmux sessionizer" })
