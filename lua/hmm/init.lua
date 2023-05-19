local a = vim.api
local t = require("hmm.htree")
local r = require("hmm.render")
local k = require("hmm.keymaps")

local app = {}

app.default_config = {
	max_parent_node_width = 25,
	max_leaf_node_width = 55,
	line_spacing = 1,
	margin = 9,
	align_levels = 0,
	initial_depth = 1,
	center_lock = true,
	focus_lock = false,
}

function app.set_offset_size(win)
	app.size = { w = a.nvim_win_get_width(win), h = a.nvim_win_get_height(win) }
	app.offset = math.floor(app.size.h / 2) - 2
end

function app.setup(config)
	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

	-- get config
	if config == nil then
		config = app.default_config
	end
	app.config = vim.tbl_extend("keep", config, app.default_config)

	-- need to reopen, else nlines is 0
	app.filename = a.nvim_exec2("echo expand('%')", { output = true }).output

	-- Get the content
	vim.cmd("e " .. app.filename)
	app.file_buf = a.nvim_get_current_buf()
	local lines = a.nvim_buf_get_lines(app.file_buf, 0, -1, false)

	-- get win, buf
	app.win = a.nvim_get_current_win()
	app.buf = a.nvim_create_buf(true, true)
	a.nvim_win_set_buf(app.win, app.buf)
  r.hide_cursor()

	-- create tree
  app.set_offset_size(app.win)
	app.tree = t.lines_to_htree(lines, app)

	-- focus root
	app.active = app.tree

	-- set global keymaps
	k.global_keymaps(app)

	-- render
	r.render(app)
end

return app
