if vim.fn.has("win32") ~= 1 then
	return
end

-- remap
vim.keymap.set({ "n", "t" }, "<C-b>c", function()
	vim.cmd("tabnew")
	vim.cmd.term()
end)
for i = 1, 9 do
	vim.keymap.set({ "n", "t" }, "<C-b>" .. i, function()
		if i >= 1 and i <= #vim.api.nvim_list_tabpages() then
			vim.cmd("tabnext " .. i)
		end
	end)
end
vim.keymap.set({ "n", "t" }, "<C-b>0", function()
	if 10 == #vim.api.nvim_list_tabpages() then
		vim.cmd("tabnext 10")
	end
end)

vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		vim.keymap.set("t", "<C-b>[", "<C-\\><C-n>", { buffer = bufnr })
		vim.keymap.set("t", "<C-b>]", "<C-v>", { buffer = bufnr })
		vim.keymap.set("n", "q", function()
			if vim.bo[bufnr].buftype == "terminal" then
				vim.cmd("startinsert")
			end
		end, { buffer = bufnr })
		vim.cmd("startinsert")
	end,
})

-- set
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
		"--header-insertion=never",
		"--completion-style=detailed",
		"--function-arg-placeholders=false",
	},
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = { "compile_commands.json", ".clangd", ".git" },
	capabilities = capabilities,
}

require("custom.msbuilder")
