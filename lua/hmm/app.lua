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

	-- get win, buf
	local buf = a.nvim_get_current_buf()
	local win = a.nvim_get_current_win()

	-- render and reset focus
	t.render(win)

	-- hot reload
	a.nvim_create_autocmd("BufWritePost", {
		group = a.nvim_create_augroup("hmm_save", { clear = true }),
		buffer = buf,
		callback = function()
			t.render(win)
		end,
	})
end

return M
