local a = vim.api
local t = require("hmm.tree")
local M = {}

M.default_config = {
	max_parent_node_width = 25,
	max_leaf_node_width = 55,
	line_spacing = 1,
	align_levels = 0,
	initial_depth = 1,
	center_lock = false,
	focus_lock = false,
	max_undo_steps = 24,
	clipboard = "os",
	clipboard_file = "/tmp/h-m-m",
	clipboard_in_command = "",
	clipboard_out_command = "",
	post_export_command = "",
	symbol1 = "✓",
	symbol2 = "✗",
}

function M.setup(config)
	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

	-- get config
	if config == nil then
		config = M.default_config
	end
	M.config = vim.tbl_extend("keep", config, M.default_config)
	P(M.config)

	-- need to reopen, else nlines is 0
	local filename = a.nvim_exec2("echo expand('%')", { output = true }).output
	vim.cmd("e " .. filename)

	-- get win, buf
	local buf = a.nvim_get_current_buf()
	local win = a.nvim_get_current_win()

	-- render and reset focus
	t.render(win)

	-- hot reload
	a.nvim_create_autocmd("BufWritePost", {
		group = a.nvim_create_augroup("hmm_save", { clear = true }),
		buffer = buf,
		callback = function()
			t.render(win)
		end,
	})
end

return M
