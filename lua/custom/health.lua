local M = {}

function M.check()
	if vim.fn.has("win32") ~= 1 then
		return
	end

	vim.health.start("clangd")

	local config_dir = vim.fn.stdpath("config")
	local repo_config = config_dir .. "\\clangd\\config.yaml"
	local appdata = os.getenv("LOCALAPPDATA") or ""
	local local_config = appdata .. "\\clangd\\config.yaml"

	if vim.fn.filereadable(repo_config) ~= 1 then
		vim.health.error("clangd config not found in repo: " .. repo_config)
		return
	end
	vim.health.ok("clangd config found in repo: " .. repo_config)

	if vim.fn.filereadable(local_config) ~= 1 then
		vim.health.error(
			"clangd config not found at: " .. local_config,
			{ 'Run: cmd.exe /c mklink /H "' .. local_config .. '" "' .. repo_config .. '"' }
		)
		return
	end
	vim.health.ok("clangd config found at: " .. local_config)

	local repo_content = vim.fn.readfile(repo_config)
	local local_content = vim.fn.readfile(local_config)
	if table.concat(repo_content, "\n") == table.concat(local_content, "\n") then
		vim.health.ok("clangd config is in sync (hard link intact)")
	else
		vim.health.warn(
			"clangd config content differs (hard link may be broken)",
			{ 'Re-create link: del "' .. local_config .. '" && cmd.exe /c mklink /H "' .. local_config .. '" "' .. repo_config .. '"' }
		)
	end

	if vim.fn.executable("clangd") == 1 then
		vim.health.ok("clangd is installed")
	else
		vim.health.warn("clangd not found in PATH")
	end

	if vim.fn.executable("ms2cc") == 1 then
		vim.health.ok("ms2cc is installed")
	else
		vim.health.warn("ms2cc not found. Install with: cargo install ms2cc")
	end
end

return M
