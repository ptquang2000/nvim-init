-- vim.pack has no `build` key, so compile fzf-native on install/update.
-- Required before vim.pack.add, or a fresh install never fires it.
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		if ev.data.spec.name ~= "telescope-fzf-native.nvim" or ev.data.kind == "delete" then
			return
		end
		-- cmake is the one path that covers both: on Linux CMAKE_BUILD_TYPE picks
		-- the opt level and --config is ignored; on Windows it is the reverse,
		-- and --install is what lifts the dll out of build/Release/.
		local src, build = ev.data.path, ev.data.path .. "/build"
		vim.system({ "cmake", "-S", src, "-B", build, "-DCMAKE_BUILD_TYPE=Release" }):wait()
		vim.system({ "cmake", "--build", build, "--config", "Release" }):wait()
		vim.system({ "cmake", "--install", build, "--prefix", build }):wait()
	end,
})
