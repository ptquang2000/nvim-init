local M = {}

M.config = {
	configuration = nil,
	platform = nil,
}

local cached_msbuild = nil
local msbuild_looked_up = false

local solution_folder_guid = "2150E333-8FDC-42A3-9474-1A3956D46DE8"

local function get_build_cores()
	local cpus = #vim.loop.cpu_info()
	return math.max(1, math.floor(cpus / 3))
end

local vs_search_paths = {
	-- VS 2022 (64-bit, in Program Files)
	{ year = "2022", edition = "Enterprise",    path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	{ year = "2022", edition = "Professional",  path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	{ year = "2022", edition = "Community",     path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	{ year = "2022", edition = "BuildTools",    path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	-- VS 2019 (32-bit, in Program Files x86)
	{ year = "2019", edition = "Enterprise",    path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Enterprise\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	{ year = "2019", edition = "Professional",  path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Professional\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	{ year = "2019", edition = "Community",     path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	{ year = "2019", edition = "BuildTools",    path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin\\MSBuild.exe" },
	-- VS 2017 (32-bit, in Program Files x86, uses 15.0 not Current)
	{ year = "2017", edition = "Enterprise",    path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Enterprise\\MSBuild\\15.0\\Bin\\MSBuild.exe" },
	{ year = "2017", edition = "Professional",  path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Professional\\MSBuild\\15.0\\Bin\\MSBuild.exe" },
	{ year = "2017", edition = "Community",     path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\MSBuild\\15.0\\Bin\\MSBuild.exe" },
	{ year = "2017", edition = "BuildTools",    path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\BuildTools\\MSBuild\\15.0\\Bin\\MSBuild.exe" },
}

local function find_msbuild()
	if msbuild_looked_up then
		return cached_msbuild
	end
	msbuild_looked_up = true

	if vim.fn.executable("msbuild") == 1 then
		cached_msbuild = "msbuild"
		return cached_msbuild
	end

	for _, entry in ipairs(vs_search_paths) do
		if vim.fn.filereadable(entry.path) == 1 then
			cached_msbuild = entry.path
			return cached_msbuild
		end
	end

	cached_msbuild = nil
	return nil
end

local function find_solution()
	local cwd = vim.fn.getcwd()
	local pattern = cwd .. "\\*.sln"
	local files = vim.fn.glob(pattern, false, true)
	if #files == 0 then
		return nil
	end
	table.sort(files)
	return files[1]
end

local function detect_vs_installations()
	local installations = {}
	for _, entry in ipairs(vs_search_paths) do
		if vim.fn.filereadable(entry.path) == 1 then
			table.insert(installations, {
				name = "Visual Studio " .. entry.year .. " " .. entry.edition,
				year = entry.year,
				edition = entry.edition,
				msbuild_path = entry.path,
			})
		end
	end
	return installations
end

local function parse_sln_projects(sln_path)
	local projects = {}
	local lines = vim.fn.readfile(sln_path)

	for _, line in ipairs(lines) do
		local type_guid, name, path, proj_guid =
			line:match('^Project%("{([^}]+)}"%)'
				.. ' = "([^"]+)", "([^"]+)", "{([^}]+)}"')
		if type_guid and name and path and proj_guid then
			if type_guid:upper() ~= solution_folder_guid:upper() then
				table.insert(projects, {
					name = name,
					path = path,
					guid = "{" .. proj_guid .. "}",
				})
			end
		end
	end

	return projects
end

local function parse_sln_configs(sln_path)
	local configs = {}
	local lines = vim.fn.readfile(sln_path)
	local in_section = false

	for _, line in ipairs(lines) do
		if line:match("GlobalSection%(SolutionConfigurationPlatforms%)") then
			in_section = true
		elseif in_section and line:match("EndGlobalSection") then
			break
		elseif in_section then
			local configuration, platform = line:match("^%s*([^|]+)|([^%s=]+)%s*=")
			if configuration and platform then
				configuration = vim.trim(configuration)
				platform = vim.trim(platform)
				local duplicate = false
				for _, c in ipairs(configs) do
					if c.configuration == configuration and c.platform == platform then
						duplicate = true
						break
					end
				end
				if not duplicate then
					table.insert(configs, {
						configuration = configuration,
						platform = platform,
					})
				end
			end
		end
	end

	return configs
end

local function get_default_config(sln_path)
	local configs = parse_sln_configs(sln_path)
	if #configs > 0 then
		return configs[1]
	end
	return { configuration = "Debug", platform = "x64" }
end

local function run_in_terminal(cmd, buf_name)
	vim.cmd("botright vsplit")
	vim.cmd("enew")
	vim.fn.termopen(cmd)
	vim.cmd("startinsert")
	local buf = vim.api.nvim_get_current_buf()
	pcall(vim.api.nvim_buf_set_name, buf, buf_name)
end

local function build_project(project, msbuild_path, sln_dir, config)
	local cores = get_build_cores()
	local sln_file = vim.fn.glob(sln_dir .. "\\*.sln", false, true)[1]
	local args = {
		msbuild_path, sln_file,
		"/p:Configuration=" .. config.configuration,
		"/p:Platform=" .. config.platform,
		"/nologo",
		"/m:" .. cores,
	}
	-- For individual projects, add /t:ProjectName (replace . and - with _)
	if project.guid then
		local target = project.name:gsub("[%.%-]", "_")
		table.insert(args, 3, "/t:" .. target)
	end
	run_in_terminal(args, "[MSBuild: " .. project.name .. "]")
end

local function clean_project(project, msbuild_path, sln_dir, config)
	local cores = get_build_cores()
	local sln_file = vim.fn.glob(sln_dir .. "\\*.sln", false, true)[1]
	local args = {
		msbuild_path, sln_file,
		"/p:Configuration=" .. config.configuration,
		"/p:Platform=" .. config.platform,
		"/nologo",
		"/m:" .. cores,
	}
	if project.guid then
		local target = project.name:gsub("[%.%-]", "_") .. ":Clean"
		table.insert(args, 3, "/t:" .. target)
	else
		table.insert(args, 3, "/t:Clean")
	end
	run_in_terminal(args, "[MSClean: " .. project.name .. "]")
end

local pickers, finders, conf, actions, action_state

local function ensure_telescope()
	pickers = pickers or require("telescope.pickers")
	finders = finders or require("telescope.finders")
	conf = conf or require("telescope.config").values
	actions = actions or require("telescope.actions")
	action_state = action_state or require("telescope.actions.state")
end

local function select_config_and_build(project, msbuild_path, sln_path)
	local sln_dir = vim.fs.dirname(sln_path)
	local configs = parse_sln_configs(sln_path)

	if #configs == 0 then
		local default_config = { configuration = "Debug", platform = "x64" }
		build_project(project, msbuild_path, sln_dir, default_config)
		return
	end

	if #configs == 1 then
		build_project(project, msbuild_path, sln_dir, configs[1])
		return
	end

	pickers.new({}, {
		prompt_title = "Build Configuration",
		finder = finders.new_table({
			results = configs,
			entry_maker = function(entry)
				local display = entry.configuration .. " | " .. entry.platform
				return {
					value = entry,
					display = display,
					ordinal = display,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					build_project(project, msbuild_path, sln_dir, selection.value)
				end
			end)
			return true
		end,
	}):find()
end

local function select_config_and_clean(project, msbuild_path, sln_path)
	local sln_dir = vim.fs.dirname(sln_path)
	local configs = parse_sln_configs(sln_path)

	if #configs == 0 then
		local default_config = { configuration = "Debug", platform = "x64" }
		clean_project(project, msbuild_path, sln_dir, default_config)
		return
	end

	if #configs == 1 then
		clean_project(project, msbuild_path, sln_dir, configs[1])
		return
	end

	pickers.new({}, {
		prompt_title = "Clean Configuration",
		finder = finders.new_table({
			results = configs,
			entry_maker = function(entry)
				local display = entry.configuration .. " | " .. entry.platform
				return {
					value = entry,
					display = display,
					ordinal = display,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					clean_project(project, msbuild_path, sln_dir, selection.value)
				end
			end)
			return true
		end,
	}):find()
end

local function pick_project(msbuild_path, sln_path, projects)
	pickers.new({}, {
		prompt_title = "Build Project",
		finder = finders.new_table({
			results = projects,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.name,
					ordinal = entry.name,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					select_config_and_build(selection.value, msbuild_path, sln_path)
				end
			end)
			return true
		end,
	}):find()
end

local function pick_project_for_clean(msbuild_path, sln_path, projects)
	pickers.new({}, {
		prompt_title = "Clean Project",
		finder = finders.new_table({
			results = projects,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.name,
					ordinal = entry.name,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					select_config_and_clean(selection.value, msbuild_path, sln_path)
				end
			end)
			return true
		end,
	}):find()
end

local function pick_vs_installation(installations, callback)
	if #installations == 1 then
		callback(installations[1].msbuild_path)
		return
	end

	pickers.new({}, {
		prompt_title = "Select Visual Studio Version",
		finder = finders.new_table({
			results = installations,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.name,
					ordinal = entry.name,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					callback(selection.value.msbuild_path)
				end
			end)
			return true
		end,
	}):find()
end

function M.select_and_build()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	ensure_telescope()

	local projects = parse_sln_projects(sln_path)
	if #projects == 0 then
		vim.notify("No buildable projects found in solution", vim.log.levels.WARN)
		return
	end

	table.insert(projects, 1, {
		name = vim.fn.fnamemodify(sln_path, ":t") .. " (entire solution)",
		path = vim.fn.fnamemodify(sln_path, ":t"),
		guid = nil,
	})

	local installations = detect_vs_installations()
	if #installations == 0 then
		vim.notify("No Visual Studio installations found. Install Visual Studio with C++ workload.", vim.log.levels.ERROR)
		return
	end

	pick_vs_installation(installations, function(msbuild_path)
		pick_project(msbuild_path, sln_path, projects)
	end)
end

function M.select_and_clean()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	ensure_telescope()

	local projects = parse_sln_projects(sln_path)
	if #projects == 0 then
		vim.notify("No cleanable projects found in solution", vim.log.levels.WARN)
		return
	end

	table.insert(projects, 1, {
		name = vim.fn.fnamemodify(sln_path, ":t") .. " (entire solution)",
		path = vim.fn.fnamemodify(sln_path, ":t"),
		guid = nil,
	})

	local installations = detect_vs_installations()
	if #installations == 0 then
		vim.notify("No Visual Studio installations found. Install Visual Studio with C++ workload.", vim.log.levels.ERROR)
		return
	end

	pick_vs_installation(installations, function(msbuild_path)
		pick_project_for_clean(msbuild_path, sln_path, projects)
	end)
end

function M.generate_compile_commands()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	if vim.fn.executable("ms2cc") ~= 1 then
		vim.notify("ms2cc not found. Install with: cargo install ms2cc", vim.log.levels.ERROR)
		return
	end

	ensure_telescope()

	local installations = detect_vs_installations()
	if #installations == 0 then
		vim.notify("No Visual Studio installations found. Install Visual Studio with C++ workload.", vim.log.levels.ERROR)
		return
	end

	pick_vs_installation(installations, function(msbuild_path)
		local sln_dir = vim.fs.dirname(sln_path)
		local configs = parse_sln_configs(sln_path)

		local function run_generate(config)
			local logfile = sln_dir .. "\\msbuild_detailed.log"
			local output = sln_dir .. "\\compile_commands.json"

			local ps_cmd = '& "' .. msbuild_path .. '" "' .. sln_path .. '"'
				.. " /t:Rebuild /nologo"
				.. " /p:Configuration=" .. config.configuration
				.. " /p:Platform=" .. config.platform
				.. ' /fl /flp:"logfile=' .. logfile .. ';verbosity=detailed"'
				.. "; ms2cc -i '" .. logfile .. "' -o '" .. output .. "' --overwrite"
				.. "; Remove-Item '" .. logfile .. "'"
				.. '; Write-Host "compile_commands.json generated successfully"'

			vim.cmd("botright vsplit")
			vim.cmd("enew")
			vim.fn.termopen({"pwsh", "-NoLogo", "-NoProfile", "-Command", ps_cmd})
			vim.cmd("startinsert")
		end

		if #configs == 0 then
			run_generate({ configuration = "Debug", platform = "x64" })
			return
		end

		if #configs == 1 then
			run_generate(configs[1])
			return
		end

		pickers.new({}, {
			prompt_title = "Build Configuration (for compile_commands)",
			finder = finders.new_table({
				results = configs,
				entry_maker = function(entry)
					local display = entry.configuration .. " | " .. entry.platform
					return {
						value = entry,
						display = display,
						ordinal = display,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						run_generate(selection.value)
					end
				end)
				return true
			end,
		}):find()
	end)
end

-- Expose internals for testing
M._find_msbuild = find_msbuild
M._find_solution = find_solution
M._detect_vs_installations = detect_vs_installations
M._parse_sln_projects = parse_sln_projects
M._parse_sln_configs = parse_sln_configs
M._get_default_config = get_default_config

-- User commands
vim.api.nvim_create_user_command("MSBuild", function() M.select_and_build() end, { desc = "MSBuild: Build project" })
vim.api.nvim_create_user_command("MSClean", function() M.select_and_clean() end, { desc = "MSBuild: Clean project" })
vim.api.nvim_create_user_command("MSGenerate", function() M.generate_compile_commands() end, { desc = "MSBuild: Generate compile_commands.json" })

-- Keybindings
vim.keymap.set("n", "<leader>bp", function()
	M.select_and_build()
end, { desc = "MSBuild: Build project" })

vim.keymap.set("n", "<leader>bc", function()
	M.select_and_clean()
end, { desc = "MSBuild: Clean project" })

vim.keymap.set("n", "<leader>bg", function()
	M.generate_compile_commands()
end, { desc = "MSBuild: Generate compile_commands.json" })

return M
