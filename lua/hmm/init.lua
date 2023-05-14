local a = vim.api
local t = require("hmm.htree")
local k = require("hmm.keymaps")

local M = {}

M.default_config = {
	max_parent_node_width = 25,
	max_leaf_node_width = 55,
	line_spacing = 1,
	align_levels = 0,
	initial_depth = 1,
	center_lock = false,
	focus_lock = false,
}

function M.set_offset_size(win)
	M.offset = { x = 0, y = 0 }
	M.size = { w = a.nvim_win_get_width(win), h = a.nvim_win_get_height(win) }
end

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

	-- need to reopen, else nlines is 0
	M.filename = a.nvim_exec2("echo expand('%')", { output = true }).output
	vim.cmd("e " .. M.filename)

	-- Get the content
	local lines = a.nvim_buf_get_lines(a.nvim_get_current_buf(), 0, -1, false)

	-- get win, buf
	M.set_offset_size(a.nvim_get_current_win())
	M.buf = a.nvim_create_buf(false, true)
	local opts = {
		relative = "editor",
		col = M.offset.x,
		row = M.offset.y,
		width = M.size.w,
		height = M.size.h,
		zindex = 20,
		style = "minimal",
	}
	M.win = a.nvim_open_win(M.buf, true, opts)
	t.clear_win_buf(M.win, M.buf)

	-- create tree
	M.tree = t.lines_to_htree(lines, M)
	M.active = M.tree

	-- set global keymaps
	k.global_keymaps(M)

	-- render
	t.render(M)

	-- somehow, cant get it to focus on the new window
	a.nvim_win_set_cursor(M.win, { M.active.y + 1, M.active.x })
end

return M
