local a = vim.api
local t = require("hmm.tree")
local M = {}

function M.setup()
	-- return if not hmm file
	local filetype = a.nvim_exec2("echo expand('%:e')", { output = true }).output
	if filetype ~= "hmm" then
		return
	end

	-- need to reopen, else nlines is 0
	local filename = a.nvim_exec2("echo expand('%')", { output = true }).output
	vim.cmd("e " .. filename)

	-- get content
	local buf = a.nvim_get_current_buf()
	local lines = a.nvim_buf_get_lines(buf, 0, -1, false)
	table.remove(lines)

	-- to tree and back
	local ptree = t.lines_to_ptree(lines)
  t.render_tree(ptree)

end

return M
