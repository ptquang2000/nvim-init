local dap = require("dap")
local dapui = require("dapui")

dap.adapters.lldb = {
	type = "executable",
	command = "/usr/bin/lldb-dap",
}

dap.configurations.cpp = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.g.project_program
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
	-- {
	-- 	name = "Attach",
	-- 	type = "lldb",
	-- 	request = "attach",
	-- 	pid = function()
	-- 		return vim.fn.input("PID: ")
	-- 	end,
	-- },
}

dap.configurations.c = dap.configurations.cpp

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.33 },
				{ id = "watches", size = 0.33 },
				{ id = "breakpoints", size = 0.33 },
			},
			size = 0.33,
			position = "left",
		},
		{
			elements = {
				{ id = "repl", size = 0.5 },
				{ id = "stacks", size = 0.5 },
			},
			size = 0.25,
			position = "bottom",
		},
	},
	controls = {
		element = "repl",
		icons = {
			pause = "󰏤",
			play = "󰐊",
			step_into = "󰆹",
			step_over = "󰆺",
			step_out = "󰆻",
			step_back = "󰆸",
			run_last = "󰑒",
			terminate = "󰧧",
		},
	},
})

require("nvim-dap-virtual-text").setup({
	enabled = true,
	enabled_commands = true,
	highlight_changed_variables = true,
	show_stop_reason = true,
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP: Continue" })
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: Breakpoint" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: Step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: Step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP: Step out" })
vim.keymap.set("n", "<S-F5>", dap.terminate, { desc = "DAP: Terminate" })
vim.keymap.set("n", "<S-F9>", function()
	dap.set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "DAP: Breakpoint (condition)" })
