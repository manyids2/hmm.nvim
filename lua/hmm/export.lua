local a = vim.api
local io = require("hmm.io")

local M = {}

M.lines = {
	default = "Export",
}

function M.open_export(app)
	local height = a.nvim_win_get_height(app.win)
	local width = a.nvim_win_get_width(app.win)

	local opts = {
		relative = "win",
		win = app.win,
		col = math.ceil(width * 0.1),
		row = math.ceil(height * 0.1),
		width = math.ceil(width * 0.8),
		height = math.ceil(height * 0.8),
		zindex = 20,
		style = "minimal",
	}
	local buf = a.nvim_create_buf(false, true)
	local win = a.nvim_open_win(buf, true, opts)
	local lines = io.pad_lines(vim.split(M.lines.default, "\n"), opts.width, opts.height)
	a.nvim_buf_set_lines(buf, 0, -1, false, lines)
	a.nvim_set_current_win(win)
	io.map_close_buffer(win, buf)
end

return M
