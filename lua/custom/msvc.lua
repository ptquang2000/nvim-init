if vim.fn.has("win32") ~= 1 then
	return
end

require("msvc").setup({
	settings = {
		default_profile = "grsc",
		build_on_save = false,
		open_quickfix = true,
	},
	default = {
		msbuild_args = { "/nologo", "/v:minimal" },
		jobs = 6,
		arch = "x64",
		vcvars_ver = "14.16",
		winsdk = "10.0.17763.0",
		compile_commands = { outdir = "bin" },
	},
	profiles = {
		grsc = {
			configuration = "Release",
			platform = "Win32",
			compile_commands = { builddir = "bin/cmake" },
		},
		grsc_arm64 = {
			configuration = "Release",
			platform = "ARM64",
			arch = "arm64",
			compile_commands = { builddir = "bin/cmake" },
		},
		driver = { configuration = "Debug", platform = "x64", vs_version = "2017" },
		fsdwd = { configuration = "release-static", platform = "x64" },
	},
})

local function msvc(sub)
	return function()
		vim.cmd("Msvc " .. sub)
	end
end

vim.keymap.set("n", "<leader>mb", msvc("build"), { desc = "Msvc: build" })
vim.keymap.set("n", "<leader>mr", msvc("rebuild"), { desc = "Msvc: rebuild" })
vim.keymap.set("n", "<leader>mc", msvc("clean"), { desc = "Msvc: clean" })
vim.keymap.set("n", "<leader>mx", msvc("cancel"), { desc = "Msvc: cancel" })
vim.keymap.set("n", "<leader>ms", msvc("status"), { desc = "Msvc: status" })
vim.keymap.set("n", "<leader>ml", msvc("log"), { desc = "Msvc: build log" })
vim.keymap.set("n", "<leader>md", msvc("discover"), { desc = "Msvc: discover solution" })
