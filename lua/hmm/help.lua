local a = vim.api
local M = {}

M.lines = {
	default = [[
         s : save
  <esc>, q : quit

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

function M.pad_lines(lines, width, height)
	local maxw = 0
	for _, line in ipairs(lines) do
		maxw = math.max(maxw, string.len(line))
	end
	local plines = {}
	for _ = 1, math.floor((height - vim.tbl_count(lines)) / 2) do
		table.insert(plines, "")
	end
	local padding = string.rep(" ", math.floor((width - maxw) / 2))
	for _, line in ipairs(lines) do
		table.insert(plines, padding .. line)
	end
	return plines
end

function M.open_help(app)
	local map = vim.keymap.set

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
	local lines = M.pad_lines(vim.split(M.lines.default, "\n"), opts.width, opts.height)
	a.nvim_buf_set_lines(buf, 0, -1, false, lines)
	a.nvim_set_current_win(win)

	-- focus active
	map("n", "<esc>", function()
		a.nvim_win_close(win, false)
		a.nvim_buf_delete(buf, { force = false })
	end, { desc = "Close help", buffer = buf })

	-- focus active
	map("n", "q", function()
		a.nvim_win_close(win, false)
		a.nvim_buf_delete(buf, { force = false })
	end, { desc = "Close help", buffer = buf })
end

return M
