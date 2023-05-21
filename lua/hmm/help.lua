local a = vim.api

local M = {}

M.cmd = "!echo $XDG_CONFIG_HOME/nvim-apps/hmm.nvim/"

function M.map(win, buf, opts, lhs, mode)
	local map = vim.keymap.set
	map("n", lhs, function()
		M.mode = mode
		M.render(win, buf, opts)
	end, { desc = mode, buffer = buf })
end

function M.open_help(_)
	local output = a.nvim_exec2(M.cmd .. "help.hmm", { output = true }).output
	local parts = vim.split(output, "\n")
	local help_path = parts[3]
	a.nvim_exec2("edit " .. help_path, {})
end

function M.open_config(_)
	local output = a.nvim_exec2(M.cmd .. "config.hmm", { output = true }).output
	local parts = vim.split(output, "\n")
	local help_path = parts[3]
	a.nvim_exec2("edit " .. help_path, {})
end

return M
