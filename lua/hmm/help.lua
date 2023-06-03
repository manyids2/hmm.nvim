local a = vim.api

local M = {}

-- we already exported, so XDG_CONFIG_HOME is guaranteed here
-- and trailing slash is important!
M.cmd = "!echo $XDG_CONFIG_HOME/nvim-apps/hmm.nvim/"

function M.map(win, buf, opts, lhs, mode)
	local map = vim.keymap.set
	map("n", lhs, function()
		M.mode = mode
		M.render(win, buf, opts)
	end, { desc = mode, buffer = buf })
end

function M.open_help(app)
	a.nvim_exec2("edit " .. app.help_file, {})
end

function M.open_config(app)
	a.nvim_exec2("edit " .. app.cfg_file, {})
end

return M
