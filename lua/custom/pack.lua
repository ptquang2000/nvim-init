-- vim.pack has no `build` key, so compile fzf-native on install/update.
-- Required before vim.pack.add, or a fresh install never fires it.
local function build_fzf(src)
  local build = src .. "/build"
  if vim.fn.has("win32") == 1 then
    vim.system({ "cmake", "-S", src, "-B", build, "-DCMAKE_BUILD_TYPE=Release" }):wait()
    vim.system({ "cmake", "--build", build, "--config", "Release" }):wait()
    vim.system({ "cmake", "--install", build, "--prefix", build }):wait()
  else
    -- Linux and macOS both use the plugin's Makefile.
    vim.system({ "make", "-C", src }):wait()
  end
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name ~= "telescope-fzf-native.nvim" or ev.data.kind == "delete" then
      return
    end
    build_fzf(ev.data.path)
  end,
})

-- Repair an installed-but-unbuilt copy (e.g. installed before this hook
-- handled the current platform), since PackChanged won't fire again for it.
local fzf_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/telescope-fzf-native.nvim"
local lib = vim.fn.has("win32") == 1 and "/build/libfzf.dll" or "/build/libfzf.so"
if vim.uv.fs_stat(fzf_dir) and not vim.uv.fs_stat(fzf_dir .. lib) then
  build_fzf(fzf_dir)
end
