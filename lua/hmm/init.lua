local a = vim.api
local io = require("hmm.io")
local ht = require("hmm.tree")
local km = require("hmm.keymaps")

local app = {
	xdg_dir = nil,
	src_dir = nil,
	cfg_file = nil,
	help_file = nil,
	state = {
		config = {},
		files = {},
		current = nil,
	},
	default_config = {
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
	},
}

function app.load_config(self)
	-- load config file using XDG_CONFIG_HOME - should be set by shell script `hmm.nvim`
	local output = a.nvim_exec2("!echo $XDG_CONFIG_HOME", { output = true }).output
	self.xdg_dir = vim.split(output, "\n", {})[3]
	self.src_dir = self.xdg_dir .. "/nvim-apps/hmm.nvim"

	-- config
	local configlist = vim.fs.find("config.hmm", { upward = false, path = self.src_dir })
	if vim.tbl_count(configlist) > 0 then
		self.cfg_file = configlist[1]
		-- parse config - just use default for now
		self.state.config = app.default_config
	else
		self.state.config = app.default_config
	end

	-- help
	local helplist = vim.fs.find("help.hmm", { upward = false, path = self.src_dir })
	if vim.tbl_count(helplist) > 0 then
		self.help_file = helplist[1]
	end
end

function app.mount(self, filename)
	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

	-- capture file buffer
	local fwin = a.nvim_get_current_win()
	local fbuf = a.nvim_get_current_buf()
	a.nvim_buf_set_option(fbuf, "buflisted", false)

	-- create hmm buffer
	local win = a.nvim_get_current_win()
	local buf = a.nvim_create_buf(true, true)

	-- set buffer name as file stem ( without .hmm )
	local ns = string.len(filename)
	a.nvim_buf_set_name(buf, string.sub(filename, 1, ns - 4))
	a.nvim_win_set_buf(win, buf)

	-- create state for each file, with ref to app
	local s = {
		app = self,
		filename = filename,
		config = self.state.config,
		fwin = fwin,
		fbuf = fbuf,
		win = win,
		buf = buf,
		root = nil,
		active = nil,
		offset = { x = 0, y = 0 },
	}

	-- read the tree
	local lines = a.nvim_buf_get_lines(fbuf, 0, -1, false)
	s.root = io.lines_to_tree(lines, s)

	-- set the state for app
	self.state.files[filename] = s
	self.state.current = filename

	-- set keymaps
	km.buffer_keymaps(s, self, buf)

	-- render
	ht.render(s)
end

function app.unmount(self)
	local s = self.state
	for _, buf in pairs(s.bufs) do
		a.nvim_buf_delete(buf, { force = true })
	end
	for _, buf in pairs(s.hbufs) do
		a.nvim_buf_delete(buf, { force = true })
	end
end

function app.setup()
	-- load config
	app:load_config()

	local filename = vim.api.nvim_exec2("echo expand('%')", { output = true }).output
	if not vim.tbl_contains(app.state.files, filename) then
		app:mount(filename)
	end
end

return app
