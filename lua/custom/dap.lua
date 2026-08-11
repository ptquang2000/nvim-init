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
				{ id = "scopes", size = 0.5 },
				{ id = "watches", size = 0.5 },
			},
			size = 0.33,
			position = "bottom",
		},
		{
			elements = {
				{ id = "stacks", size = 0.7 },
				{ id = "repl", size = 0.3 },
			},
			size = 0.5,
			position = "right",
		},
	},
	controls = {
		element = "repl",
		icons = {
			pause = "",
			play = "",
			step_over = "",
			step_into = "",
			step_out = "",
			run_last = "",
			terminate = "",
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
vim.keymap.set("n", "<F17>", dap.terminate, { desc = "DAP: Terminate <S-F5>" })
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: Breakpoint" })
vim.keymap.set("n", "<F21>", function()
	dap.set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "DAP: Breakpoint (condition) <S-F9>" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: Step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: Step into" })
vim.keymap.set("n", "<F23>", dap.step_out, { desc = "DAP: Step out <S-F11>" })
