require("bootstrap")
vim.cmd([[set background=dark]])
vim.cmd([[colorscheme moonfly]])

local a = vim.api
local hmm_open = a.nvim_create_augroup("hmm_open", { clear = true })
a.nvim_create_autocmd({ "BufRead" }, {
	group = hmm_open,
	pattern = { "*.hmm" },
	callback = function()
		require("hmm").setup()
	end,
})
