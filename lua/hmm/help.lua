local a = vim.api
local io = require("hmm.io")

local M = {}

M.lines = {
	default = [[
         s : save
  <esc>, q : quit
         ? : help
     <C-x> : export

     ↑ , k : up
     ↓ , j : down
     ← , h : left
     → , l : right
   <space> : toggle children

<enter>, o : new sibling
  <tab>, O : new child
         d : delete node and descendents

         J : move node down
         K : move node up

]],
	nodes = [[
         s : save
  <esc>, q : quit
<enter>, o : new sibling
  <tab>, O : new child
         d : delete node and descendents
]],
	marks = [[
o, <enter> : new sibling
O,   <tab> : new child
         d : delete node and descendents
]],
}

function M.open_help(app)
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
