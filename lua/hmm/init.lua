local a = vim.api
-- local io = require("hmm.io")
-- local ht = require("hmm.tree")
-- local km = require("hmm.keymaps")

local app = {}

app.state = {
	config = {},
	open = {},
	wins = {},
	bufs = {},
	current = nil,
}

app.default_config = {
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
	colorscheme = "carbonfox",
	background = "dark",
}

function app.load_config(self)
	-- load config file using XDG_CONFIG_HOME - should be set by shell script `hmm.nvim`
	local output = a.nvim_exec2("!echo $XDG_CONFIG_HOME", { output = true }).output
	self.xdg_dir = vim.split(output, "\n", {})[3]
	self.src_dir = self.xdg_dir .. "/nvim-apps/hmm.nvim"

	-- config
	local configlist = vim.fs.find("config.yaml", { upward = false, path = self.src_dir })
	if vim.tbl_count(configlist) > 0 then
		self.cfg_file = configlist[1]
		-- parse config - just use default for now
		self.state.config = app.default_config
	else
		self.state.config = app.default_config
	end

	-- help
	local helplist = vim.fs.find("help.yaml", { upward = false, path = self.src_dir })
	if vim.tbl_count(helplist) > 0 then
		self.help_file = helplist[1]
	end
end

function app.mount(self, filename)
	local s = self.state

	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

	-- Capture buffer
	table.insert(s.open, filename)
	local win = a.nvim_get_current_win()
	local buf = a.nvim_get_current_buf()
	a.nvim_buf_set_option(buf, "buflisted", false)
	s.wins[filename] = win
	s.bufs[filename] = buf
	s.current = filename

	-- reload config
	app:load_config()
end

function app.unmount(self)
	local s = self.state
	for _, buf in pairs(s.bufs) do
		a.nvim_buf_delete(buf, { force = true })
	end
end

function app.setup()
	local filename = vim.api.nvim_exec2("echo expand('%')", { output = true }).output
	app:mount(filename)
	P(app.state)
end

-- function app.init(config)
-- 	local app = {}
-- 	-- get config
-- 	if config == nil then
-- 		config = app.default_config
-- 	end
-- 	app.config = vim.tbl_extend("keep", config, app.default_config)
--
-- 	-- need to reopen, else nlines is 0
-- 	app.filename = a.nvim_exec2("echo expand('%')", { output = true }).output
--
-- 	-- Get the content
-- 	vim.cmd("e " .. app.filename)
-- 	app.file_buf = a.nvim_get_current_buf()
-- 	a.nvim_buf_set_option(app.file_buf, "buflisted", false)
--
-- 	-- get win, buf
-- 	app.win = a.nvim_get_current_win()
-- 	app.buf = a.nvim_create_buf(true, true)
-- 	local ns = string.len(app.filename)
-- 	a.nvim_buf_set_name(app.buf, string.sub(app.filename, 1, ns - 4))
-- 	a.nvim_win_set_buf(app.win, app.buf)
--
-- 	app.offset = { x = 0, y = 0 }
-- 	return app
-- end

-- function app.setup(config)
-- 	-- return if not hmm file
-- 	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
-- 	if filetype ~= "hmm" then
-- 		return
-- 	end
--
-- 	-- BUG: this check is not working
-- 	local filename = a.nvim_exec2("echo expand('%')", { output = true }).output
-- 	local ns = string.len(filename)
-- 	local fname = string.sub(filename, 1, ns - 4)
-- 	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
-- 		local bufname = vim.api.nvim_buf_get_name(buf)
-- 		if bufname == fname then
-- 			return
-- 		end
-- 	end
--
-- 	-- initialize win, buf, filename, etc
-- 	local app = app.init(config)
--
-- 	-- read file and parse to tree
-- 	io.reload(app)
--
-- 	-- set app keymaps
-- 	km.buffer_keymaps(app)
--
-- 	-- finally, render
-- 	ht.render(app)
-- end

return app
