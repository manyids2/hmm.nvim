local a = vim.api

require("bootstrap")

-- here till we hook up telescope to update config
vim.cmd("colorscheme oxocarbon")
vim.cmd("set background=dark")

local function write_filename(filename)
	local buf = a.nvim_get_current_buf()
	local filename_stem = string.sub(filename, 0, string.len(filename) - 4)
	a.nvim_buf_set_lines(buf, 0, 1, false, { filename_stem })
	vim.cmd("w " .. filename)
end

-- handle first open
local filename = vim.api.nvim_exec2("echo expand('%')", { output = true }).output
if filename == "" then
	vim.ui.input({ prompt = "New: " }, function(text)
		-- get filename from input
		filename = vim.trim(text) .. ".hmm"
		write_filename(filename)
		-- open the file
		require("hmm").setup()
	end)
else
	-- if file does not exist, first save it
	if vim.tbl_count(vim.fs.find(filename, { upward = false })) == 0 then
		write_filename(filename)
		-- open the file
		require("hmm").setup()
	end
end

-- handle hmm file
local hmm_open = a.nvim_create_augroup("hmm_open", { clear = true })
a.nvim_create_autocmd({ "BufRead" }, {
	group = hmm_open,
	pattern = { "*.hmm" },
	callback = function()
		require("hmm").setup()
	end,
})
