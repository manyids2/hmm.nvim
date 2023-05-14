local a = vim.api
local t = require("hmm.htree")

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

	-- set global keymaps
	M.global_keymaps()

	-- get win, buf
	M.buf = a.nvim_create_buf(false, true)
	M.win = a.nvim_get_current_win()
	a.nvim_win_set_buf(M.win, M.buf)
	M.set_offset_size(M.win)
	t.clear_win_buf(M.win, M.buf)

	-- create default tree
	M.tree = t.new_Tree(0, 0, "root")

	-- create tree, render
	t.render(M, lines)
end

function M.global_keymaps()
	local map = vim.keymap.set
	-- focus root
	map("n", "m", function()
		a.nvim_set_current_win(M.tree.win)
	end, { desc = "Focus root" })

	-- save to source
	map("n", "s", function()
		vim.notify("Saved " .. M.filename)
	end, { desc = "Save" })
end

return M
