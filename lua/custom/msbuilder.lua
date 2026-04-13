local M = {}

M.config = {
	configuration = nil,
	platform = nil,
}

local cached_msbuild = nil
local msbuild_looked_up = false

local saved_chains = {}
local active_job_id = nil
local active_buf = nil

local function move_to_front(list, predicate)
	for i, item in ipairs(list) do
		if predicate(item) then
			table.remove(list, i)
			table.insert(list, 1, item)
			return
		end
	end
end

local function chains_match(a, b)
	return a.msbuild_path == b.msbuild_path
		and a.project.name == b.project.name
		and a.config.configuration == b.config.configuration
		and a.config.platform == b.config.platform
end

local function save_chain(chain)
	for i, existing in ipairs(saved_chains) do
		if chains_match(existing, chain) then
			table.remove(saved_chains, i)
			break
		end
	end
	table.insert(saved_chains, 1, chain)
end

local function chain_display(chain)
	return chain.project.name .. " | " .. chain.config.configuration .. " | " .. chain.config.platform
end

local function is_build_running()
	if active_job_id and active_buf and vim.api.nvim_buf_is_valid(active_buf) then
		return true
	end
	active_job_id = nil
	active_buf = nil
	return false
end

local solution_folder_guid = "2150E333-8FDC-42A3-9474-1A3956D46DE8"

local function get_build_cores()
	local cpus = #vim.loop.cpu_info()
	return math.max(1, math.floor(cpus / 2))
end

local vs_search_paths = {
	-- VS 2022 (64-bit, in Program Files)
	{
		year = "2022",
		edition = "Enterprise",
		path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Enterprise\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	{
		year = "2022",
		edition = "Professional",
		path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	{
		year = "2022",
		edition = "Community",
		path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	{
		year = "2022",
		edition = "BuildTools",
		path = "C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	-- VS 2019 (32-bit, in Program Files x86)
	{
		year = "2019",
		edition = "Enterprise",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Enterprise\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	{
		year = "2019",
		edition = "Professional",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Professional\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	{
		year = "2019",
		edition = "Community",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	{
		year = "2019",
		edition = "BuildTools",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\MSBuild\\Current\\Bin\\MSBuild.exe",
	},
	-- VS 2017 (32-bit, in Program Files x86, uses 15.0 not Current)
	{
		year = "2017",
		edition = "Enterprise",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Enterprise\\MSBuild\\15.0\\Bin\\MSBuild.exe",
	},
	{
		year = "2017",
		edition = "Professional",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Professional\\MSBuild\\15.0\\Bin\\MSBuild.exe",
	},
	{
		year = "2017",
		edition = "Community",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\MSBuild\\15.0\\Bin\\MSBuild.exe",
	},
	{
		year = "2017",
		edition = "BuildTools",
		path = "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\BuildTools\\MSBuild\\15.0\\Bin\\MSBuild.exe",
	},
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
			line:match('^Project%("{([^}]+)}"%)' .. ' = "([^"]+)", "([^"]+)", "{([^}]+)}"')
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

local ms2cc_job_id = nil

local function run_ms2cc(sln_dir)
	local logfile = sln_dir .. "\\msbuild_detailed.log"
	local output = sln_dir .. "\\compile_commands.json"
	if vim.fn.filereadable(logfile) ~= 1 then
		vim.notify("msbuild_detailed.log not found, skipping compile_commands.json generation", vim.log.levels.WARN)
		return
	end
	if vim.fn.executable("ms2cc") ~= 1 then
		vim.notify("ms2cc not found. Install with: cargo install ms2cc", vim.log.levels.WARN)
		return
	end
	local args = { "ms2cc", "-i", logfile, "-o", output, "--no-progress" }
	vim.notify("Generating compile_commands.json...", vim.log.levels.INFO)
	local stderr_lines = {}
	ms2cc_job_id = vim.fn.jobstart(args, {
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				if line ~= "" then
					table.insert(stderr_lines, line)
				end
			end
		end,
		on_exit = function(_, code)
			ms2cc_job_id = nil
			vim.schedule(function()
				if code == 0 then
					vim.fn.delete(logfile)
					vim.notify("compile_commands.json generated successfully", vim.log.levels.INFO)
				else
					local msg = "ms2cc failed (exit " .. code .. ")"
					if #stderr_lines > 0 then
						msg = msg .. ": " .. table.concat(stderr_lines, " ")
					end
					vim.notify(msg, vim.log.levels.ERROR)
				end
			end)
		end,
	})
end

local function run_in_terminal(cmd, buf_name, opts)
	opts = opts or {}
	if is_build_running() then
		vim.notify("A build is already running", vim.log.levels.WARN)
		return
	end
	if ms2cc_job_id then
		vim.notify("compile_commands.json generation is still running", vim.log.levels.WARN)
		return
	end
	local display_parts = {}
	for _, arg in ipairs(cmd) do
		if arg:find(" ") then
			table.insert(display_parts, '"' .. arg .. '"')
		else
			table.insert(display_parts, arg)
		end
	end
	vim.notify(">> " .. table.concat(display_parts, " "), vim.log.levels.INFO)
	vim.cmd("botright vsplit")
	vim.cmd("enew")
	local env = vim.fn.environ()
	env["CMAKE_EXPORT_COMPILE_COMMANDS"] = "ON"
	local job_id = vim.fn.termopen(cmd, {
		env = env,
		on_exit = function(_, exit_code)
			active_job_id = nil
			active_buf = nil
			if exit_code == 0 and opts.on_success then
				vim.schedule(opts.on_success)
			end
		end,
	})
	active_job_id = job_id
	active_buf = vim.api.nvim_get_current_buf()
	vim.cmd("normal! G")
	vim.cmd("startinsert")
	pcall(vim.api.nvim_buf_set_name, active_buf, buf_name)
end

local function build_project(project, msbuild_path, sln_dir, config)
	local cores = get_build_cores()
	local sln_file = vim.fn.glob(sln_dir .. "\\*.sln", false, true)[1]
	local logfile = sln_dir .. "\\msbuild_detailed.log"
	local args = {
		msbuild_path,
		sln_file,
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
	table.insert(args, "/fl")
	table.insert(args, "/flp:logfile=" .. logfile .. ";verbosity=detailed")
	-- Delete stale log before starting
	vim.fn.delete(logfile)
	run_in_terminal(args, "[MSBuild: " .. project.name .. "]", {
		on_success = function()
			run_ms2cc(sln_dir)
		end,
	})
end

local function clean_project(project, msbuild_path, sln_dir, config)
	local cores = get_build_cores()
	local sln_file = vim.fn.glob(sln_dir .. "\\*.sln", false, true)[1]
	local args = {
		msbuild_path,
		sln_file,
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

local function rebuild_project(project, msbuild_path, sln_dir, config)
	local cores = get_build_cores()
	local sln_file = vim.fn.glob(sln_dir .. "\\*.sln", false, true)[1]
	local logfile = sln_dir .. "\\msbuild_detailed.log"
	local args = {
		msbuild_path,
		sln_file,
		"/p:Configuration=" .. config.configuration,
		"/p:Platform=" .. config.platform,
		"/nologo",
		"/m:" .. cores,
	}
	if project.guid then
		local target = project.name:gsub("[%.%-]", "_") .. ":Rebuild"
		table.insert(args, 3, "/t:" .. target)
	else
		table.insert(args, 3, "/t:Rebuild")
	end
	table.insert(args, "/fl")
	table.insert(args, "/flp:logfile=" .. logfile .. ";verbosity=detailed")
	-- Delete stale log before starting
	vim.fn.delete(logfile)
	run_in_terminal(args, "[MSRebuild: " .. project.name .. "]", {
		on_success = function()
			run_ms2cc(sln_dir)
		end,
	})
end

local pickers, finders, conf, actions, action_state

local function ensure_telescope()
	pickers = pickers or require("telescope.pickers")
	finders = finders or require("telescope.finders")
	conf = conf or require("telescope.config").values
	actions = actions or require("telescope.actions")
	action_state = action_state or require("telescope.actions.state")
end

local function pick_chain_or_new(prompt_title, on_chain, on_new)
	if #saved_chains == 0 then
		on_new()
		return
	end

	ensure_telescope()

	local entries = {}
	for _, chain in ipairs(saved_chains) do
		table.insert(entries, { chain = chain, display = chain_display(chain) })
	end
	table.insert(entries, { chain = nil, display = "[New selection...]" })

	pickers
		.new({}, {
			prompt_title = prompt_title,
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.display,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						if selection.value.chain then
							on_chain(selection.value.chain)
						else
							on_new()
						end
					end
				end)
				return true
			end,
		})
		:find()
end

local function select_config_and_build(project, msbuild_path, sln_path)
	local sln_dir = vim.fs.dirname(sln_path)
	local configs = parse_sln_configs(sln_path)

	if saved_chains[1] then
		move_to_front(configs, function(c)
			return c.configuration == saved_chains[1].config.configuration
				and c.platform == saved_chains[1].config.platform
		end)
	end

	if #configs == 0 then
		local default_config = { configuration = "Debug", platform = "x64" }
		save_chain({ msbuild_path = msbuild_path, project = project, config = default_config })
		build_project(project, msbuild_path, sln_dir, default_config)
		return
	end

	if #configs == 1 then
		save_chain({ msbuild_path = msbuild_path, project = project, config = configs[1] })
		build_project(project, msbuild_path, sln_dir, configs[1])
		return
	end

	pickers
		.new({}, {
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
						save_chain({ msbuild_path = msbuild_path, project = project, config = selection.value })
						build_project(project, msbuild_path, sln_dir, selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

local function select_config_and_clean(project, msbuild_path, sln_path)
	local sln_dir = vim.fs.dirname(sln_path)
	local configs = parse_sln_configs(sln_path)

	if saved_chains[1] then
		move_to_front(configs, function(c)
			return c.configuration == saved_chains[1].config.configuration
				and c.platform == saved_chains[1].config.platform
		end)
	end

	if #configs == 0 then
		local default_config = { configuration = "Debug", platform = "x64" }
		save_chain({ msbuild_path = msbuild_path, project = project, config = default_config })
		clean_project(project, msbuild_path, sln_dir, default_config)
		return
	end

	if #configs == 1 then
		save_chain({ msbuild_path = msbuild_path, project = project, config = configs[1] })
		clean_project(project, msbuild_path, sln_dir, configs[1])
		return
	end

	pickers
		.new({}, {
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
						save_chain({ msbuild_path = msbuild_path, project = project, config = selection.value })
						clean_project(project, msbuild_path, sln_dir, selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

local function select_config_and_rebuild(project, msbuild_path, sln_path)
	local sln_dir = vim.fs.dirname(sln_path)
	local configs = parse_sln_configs(sln_path)

	if saved_chains[1] then
		move_to_front(configs, function(c)
			return c.configuration == saved_chains[1].config.configuration
				and c.platform == saved_chains[1].config.platform
		end)
	end

	if #configs == 0 then
		local default_config = { configuration = "Debug", platform = "x64" }
		save_chain({ msbuild_path = msbuild_path, project = project, config = default_config })
		rebuild_project(project, msbuild_path, sln_dir, default_config)
		return
	end

	if #configs == 1 then
		save_chain({ msbuild_path = msbuild_path, project = project, config = configs[1] })
		rebuild_project(project, msbuild_path, sln_dir, configs[1])
		return
	end

	pickers
		.new({}, {
			prompt_title = "Rebuild Configuration",
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
						save_chain({ msbuild_path = msbuild_path, project = project, config = selection.value })
						rebuild_project(project, msbuild_path, sln_dir, selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

local function pick_project(msbuild_path, sln_path, projects)
	if saved_chains[1] then
		move_to_front(projects, function(p)
			return p.name == saved_chains[1].project.name
		end)
	end

	pickers
		.new({}, {
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
		})
		:find()
end

local function pick_project_for_clean(msbuild_path, sln_path, projects)
	if saved_chains[1] then
		move_to_front(projects, function(p)
			return p.name == saved_chains[1].project.name
		end)
	end

	pickers
		.new({}, {
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
		})
		:find()
end

local function pick_project_for_rebuild(msbuild_path, sln_path, projects)
	if saved_chains[1] then
		move_to_front(projects, function(p)
			return p.name == saved_chains[1].project.name
		end)
	end

	pickers
		.new({}, {
			prompt_title = "Rebuild Project",
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
						select_config_and_rebuild(selection.value, msbuild_path, sln_path)
					end
				end)
				return true
			end,
		})
		:find()
end

local function pick_vs_installation(installations, callback)
	if saved_chains[1] then
		move_to_front(installations, function(inst)
			return inst.msbuild_path == saved_chains[1].msbuild_path
		end)
	end

	if #installations == 1 then
		callback(installations[1].msbuild_path)
		return
	end

	pickers
		.new({}, {
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
		})
		:find()
end

function M.select_and_build()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	ensure_telescope()

	pick_chain_or_new("MSBuild", function(chain)
		local sln_dir = vim.fs.dirname(sln_path)
		save_chain(chain)
		build_project(chain.project, chain.msbuild_path, sln_dir, chain.config)
	end, function()
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
			vim.notify(
				"No Visual Studio installations found. Install Visual Studio with C++ workload.",
				vim.log.levels.ERROR
			)
			return
		end

		pick_vs_installation(installations, function(msbuild_path)
			pick_project(msbuild_path, sln_path, projects)
		end)
	end)
end

function M.select_and_clean()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	ensure_telescope()

	pick_chain_or_new("MSClean", function(chain)
		local sln_dir = vim.fs.dirname(sln_path)
		save_chain(chain)
		clean_project(chain.project, chain.msbuild_path, sln_dir, chain.config)
	end, function()
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
			vim.notify(
				"No Visual Studio installations found. Install Visual Studio with C++ workload.",
				vim.log.levels.ERROR
			)
			return
		end

		pick_vs_installation(installations, function(msbuild_path)
			pick_project_for_clean(msbuild_path, sln_path, projects)
		end)
	end)
end

function M.select_and_rebuild()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	ensure_telescope()

	pick_chain_or_new("MSRebuild", function(chain)
		local sln_dir = vim.fs.dirname(sln_path)
		save_chain(chain)
		rebuild_project(chain.project, chain.msbuild_path, sln_dir, chain.config)
	end, function()
		local projects = parse_sln_projects(sln_path)
		if #projects == 0 then
			vim.notify("No rebuildable projects found in solution", vim.log.levels.WARN)
			return
		end

		table.insert(projects, 1, {
			name = vim.fn.fnamemodify(sln_path, ":t") .. " (entire solution)",
			path = vim.fn.fnamemodify(sln_path, ":t"),
			guid = nil,
		})

		local installations = detect_vs_installations()
		if #installations == 0 then
			vim.notify(
				"No Visual Studio installations found. Install Visual Studio with C++ workload.",
				vim.log.levels.ERROR
			)
			return
		end

		pick_vs_installation(installations, function(msbuild_path)
			pick_project_for_rebuild(msbuild_path, sln_path, projects)
		end)
	end)
end

function M.generate_compile_commands()
	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end
	if ms2cc_job_id then
		vim.notify("compile_commands.json generation is already running", vim.log.levels.WARN)
		return
	end
	local sln_dir = vim.fs.dirname(sln_path)
	run_ms2cc(sln_dir)
end

function M.compile_current_file()
	local filepath = vim.api.nvim_buf_get_name(0)
	if filepath == "" then
		vim.notify("No file in current buffer", vim.log.levels.ERROR)
		return
	end

	local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
	local valid_exts = { c = true, cpp = true, cc = true, cxx = true, h = true, hpp = true }
	if not valid_exts[ext] then
		vim.notify("Not a C/C++ file: " .. ext, vim.log.levels.ERROR)
		return
	end

	local sln_path = find_solution()
	if not sln_path then
		vim.notify("No .sln file found in " .. vim.fn.getcwd(), vim.log.levels.ERROR)
		return
	end

	local msbuild_path = find_msbuild()
	if not msbuild_path then
		vim.notify("MSBuild not found. Install Visual Studio with C++ workload.", vim.log.levels.ERROR)
		return
	end

	local sln_dir = vim.fs.dirname(sln_path)
	local config = M.config.configuration and M.config or (saved_chains[1] and saved_chains[1].config) or get_default_config(sln_path)

	-- Make file path relative to solution directory
	local relative_path = vim.fn.fnamemodify(filepath, ":.")
	local sln_dir_prefix = vim.fn.fnamemodify(sln_dir, ":.")
	if relative_path:sub(1, #sln_dir_prefix) == sln_dir_prefix then
		relative_path = relative_path:sub(#sln_dir_prefix + 2)
	end

	local filename = vim.fn.fnamemodify(filepath, ":t")
	local args = {
		msbuild_path,
		sln_path,
		"/p:Configuration=" .. config.configuration,
		"/p:Platform=" .. config.platform,
		"/p:SelectedFiles=" .. relative_path,
		"/nologo",
	}
	run_in_terminal(args, "[MSCompile: " .. filename .. "]")
end

-- Expose internals for testing
M._find_msbuild = find_msbuild
M._find_solution = find_solution
M._detect_vs_installations = detect_vs_installations
M._parse_sln_projects = parse_sln_projects
M._parse_sln_configs = parse_sln_configs
M._get_default_config = get_default_config

-- User commands
vim.api.nvim_create_user_command("MSBuild", function()
	M.select_and_build()
end, { desc = "MSBuild: Build project" })
vim.api.nvim_create_user_command("MSClean", function()
	M.select_and_clean()
end, { desc = "MSBuild: Clean project" })
vim.api.nvim_create_user_command("MSRebuild", function()
	M.select_and_rebuild()
end, { desc = "MSBuild: Rebuild project" })
vim.api.nvim_create_user_command("MSCompile", function()
	M.compile_current_file()
end, { desc = "MSBuild: Compile current file" })
vim.api.nvim_create_user_command("MSGenerate", function()
	M.generate_compile_commands()
end, { desc = "MSBuild: Generate compile_commands.json" })

return M
