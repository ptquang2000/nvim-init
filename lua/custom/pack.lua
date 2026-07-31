-- vim.pack has no `build` key, so compile fzf-native on install/update.
-- Required before vim.pack.add, or a fresh install never fires it.
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		if ev.data.spec.name ~= "telescope-fzf-native.nvim" or ev.data.kind == "delete" then
			return
		end
		local src, build = ev.data.path, ev.data.path .. "/build"
		if vim.fn.has("win32") == 1 then
			vim.system({ "cmake", "-S", src, "-B", build, "-DCMAKE_BUILD_TYPE=Release" }):wait()
			vim.system({ "cmake", "--build", build, "--config", "Release" }):wait()
			vim.system({ "cmake", "--install", build, "--prefix", build }):wait()
		elseif vim.fn.has("linux") == 1 then
			vim.system({ "make", "-C", src }):wait()
		end
	end,
})
