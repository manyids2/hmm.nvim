local a = vim.api
local io = require("hmm.io")
local ht = require("hmm.tree")

local app = {}

app.default_config = {
	margin = 9,
	line_spacing = 1,
	align_levels = 0,
	initial_depth = 1,
	focus_lock = false,
	center_lock = true,
	max_leaf_node_width = 55,
	max_parent_node_width = 25,
}

function app.init(config)
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

	-- get win, buf
	app.win = a.nvim_get_current_win()
	app.buf = a.nvim_create_buf(true, true)
	a.nvim_win_set_buf(app.win, app.buf)
end

function app.setup(config)
	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

	app.init(config)
end

return app
