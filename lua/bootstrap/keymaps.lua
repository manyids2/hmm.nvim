-- keymaps
local function map(mode, lhs, rhs, opts)
	opts = opts or {}
	opts.silent = opts.silent ~= false
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- quit, save
map("n", "q", "<cmd>qa<cr>", { desc = "Quit all" })

-- For comfort options
map("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>c", "<cmd>:Telescope colorscheme<cr>", { desc = "Colorscheme" })
