local a = vim.api
local io = require("hmm.io")
local ht = require("hmm.tree")
local km = require("hmm.keymaps")

local M = {}

M.default_config = {
	margin = 9,
	line_spacing = 1,
	initial_depth = 1,
	focus_lock = false,
	center_lock = true,
	align_levels = false,
	max_leaf_node_width = 55,
	max_parent_node_width = 25,
	list_indent = 4,
	x_speed = 5,
	y_speed = 2,
	mode = "tree",
	clipboard = {},
}

function M.init(config)
	local app = {}
	-- get config
	if config == nil then
		config = M.default_config
	end
	app.config = vim.tbl_extend("keep", config, M.default_config)

	-- need to reopen, else nlines is 0
	app.filename = a.nvim_exec2("echo expand('%')", { output = true }).output

	-- Get the content
	vim.cmd("e " .. app.filename)
	app.file_buf = a.nvim_get_current_buf()
	a.nvim_buf_set_option(app.file_buf, "buflisted", false)

	-- get win, buf
	app.win = a.nvim_get_current_win()
	app.buf = a.nvim_create_buf(true, true)
	local ns = string.len(app.filename)
	a.nvim_buf_set_name(app.buf, string.sub(app.filename, 1, ns - 4))
	a.nvim_win_set_buf(app.win, app.buf)

	app.offset = { x = 0, y = 0 }
	return app
end

function M.setup(config)
	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

  -- BUG: this check is not working
	local filename = a.nvim_exec2("echo expand('%')", { output = true }).output
	local ns = string.len(filename)
	local fname = string.sub(filename, 1, ns - 4)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local bufname = vim.api.nvim_buf_get_name(buf)
		if bufname == fname then
			return
		end
	end

	-- initialize win, buf, filename, etc
	local app = M.init(config)

	-- read file and parse to tree
	io.reload(app)

	-- set app keymaps
	km.buffer_keymaps(app)

	-- finally, render
	ht.render(app)
end

return M
