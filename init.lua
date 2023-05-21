require("bootstrap")

-- here till we hook up telescope to update config
vim.cmd("colorscheme oxocarbon")
vim.cmd("set background=dark")

local a = vim.api
local hmm_open = a.nvim_create_augroup("hmm_open", { clear = true })
a.nvim_create_autocmd({ "BufRead" }, {
	group = hmm_open,
	pattern = { "*.hmm" },
	callback = function()
		require("hmm").setup()
	end,
})
