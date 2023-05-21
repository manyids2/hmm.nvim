local a = vim.api
local io = require("hmm.io")

local M = {}

function M.map(win, buf, opts, lhs, mode)
	local map = vim.keymap.set
	map("n", lhs, function()
		M.mode = mode
		M.render(win, buf, opts)
	end, { desc = mode, buffer = buf })
end

M.shortcuts = [[

  (<enter>) General (n) Node (v) View (f) File

]]
M.lines = {
	general = M.shortcuts .. [[

  General:

         ?  ───  help
         q  ───  quit
     <esc>  ───  refresh
     <C-s>  ───  reload ( harder refresh )
     <C-x>  ───  export

         b  ───  open all
         B  ───  close all
   <space>  ───  toggle children

     ↑ , k  ───  to prev sibling
     ↓ , j  ───  to next sibling
     ← , h  ───  to parent
     → , l  ───  to child

        ;c  ───  colorschemes
        ;f  ───  find file ( press <esc> after it opens  )

]],
	node = M.shortcuts .. [[

  Node actions:

   <space>  ───  toggle children
  <tab>, O  ───  new child
<enter>, o  ───  new sibling
e, a, s, i  ───  edit, keeping current text
E, A, S, I  ───  edit from blank

         J  ───  move node down
         K  ───  move node up

  <delete>  ───  delete node and descendents
         d  ───  cut node and descendents
         y  ───  copy node and descendents
         p  ───  paste as child
         P  ───  paste as sibling

]],
	view = M.shortcuts .. [[

  View actions:

         0  ───  reset origin
     <M-k>  ───  pan up
     <M-j>  ───  pan down
     <M-h>  ───  pan left
     <M-l>  ───  pan right

         c  ───  focus active node
         C  ───  toggle focus lock
      ~, m  ───  focus root

]],
	file = M.shortcuts .. [[

  File actions:

         H  ───  next file
         L  ───  prev file

        ;f  ───  find file ( press <esc> after it opens  )
        ;g  ───  search all files

       ;ds  ───  open directory in split
       ;df  ───  open directory in float

]],
}

function M.render(win, buf, opts)
	local w = math.ceil(opts.width * 0.1)
	local h = math.ceil(opts.height * 0.1)
	local lines = io.pad_left_top(vim.split(M.lines[M.mode], "\n"), w, h)
	a.nvim_buf_set_lines(buf, 0, -1, false, lines)
	a.nvim_set_current_win(win)
	io.map_close_buffer(win, buf)
end

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

	M.mode = "general"
	M.map(win, buf, opts, "<enter>", "general")
	M.map(win, buf, opts, "n", "node")
	M.map(win, buf, opts, "v", "view")
	M.map(win, buf, opts, "f", "file")
	M.render(win, buf, opts)
end

return M
