if vim.fn.has("win32") ~= 1 then
	return
end

require("msvc").setup({
	settings = {
		echo_command = false,
		build_on_save = false,
		open_quickfix = true,
		qf_height = 10,
		auto_select_sln = true,
		search_depth = 4,
		cache_env = true,
		compile_commands = {
			outdir = "bin",
			builddir = "bin/cmake",
		},
	},
	profiles = {
		default = {
			vs_version = "latest",
			arch = "x64",
			host_arch = "x64",
			msbuild_args = { "/nologo", "/v:minimal" },
			jobs = 6,
			vcvars_ver = "14.16",
			winsdk = "10.0.17763.0",
		},
		grsc = {
			configuration = "Release",
			platform = "Win32",
			arch = "x86",
		},
		driver = {
			configuration = "Debug",
			platform = "x64",
			arch = "x64",
		},
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
vim.keymap.set("n", "<leader>ml", msvc("build_log"), { desc = "Msvc: build log" })
vim.keymap.set("n", "<leader>md", msvc("discover"), { desc = "Msvc: discover solution" })
