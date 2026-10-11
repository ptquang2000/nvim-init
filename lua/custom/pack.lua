-- vim.pack has no `build` key, so compile fzf-native on install/update.
-- Required before vim.pack.add, or a fresh install never fires it.
local function build_fzf(src)
  local build = src .. "/build"
  local steps
  if vim.fn.has("win32") == 1 then
    -- Outside a vcvars shell CMake's default NMake/MSVC finds no compiler,
    -- so use Ninja + clang when present. --fresh drops a cache left by a
    -- failed run with another generator.
    local configure = { "cmake", "--fresh", "-S", src, "-B", build, "-DCMAKE_BUILD_TYPE=Release" }
    if vim.fn.executable("ninja") == 1 and vim.fn.executable("clang") == 1 then
      vim.list_extend(configure, { "-G", "Ninja", "-DCMAKE_C_COMPILER=clang" })
    end
    steps = {
      configure,
      { "cmake", "--build", build, "--config", "Release" },
      { "cmake", "--install", build, "--prefix", build },
    }
  else
    -- Linux and macOS both use the plugin's Makefile.
    steps = { { "make", "-C", src } }
  end
  for _, cmd in ipairs(steps) do
    local res = vim.system(cmd, { text = true }):wait()
    if res.code ~= 0 then
      vim.notify(("fzf-native build failed: %s\n%s%s"):format(table.concat(cmd, " "), res.stdout, res.stderr),
        vim.log.levels.ERROR)
      return
    end
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
