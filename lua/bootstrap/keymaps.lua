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

-- splits
map("n", "+", "<cmd>set wh=999<cr><cmd>set wiw=999<cr>", { desc = "Maximize window" })
map("n", "=", "<cmd>set wh=10<cr><cmd>set wiw=10<cr><cmd>wincmd =<cr>", { desc = "Equalize windows" })

-- Move to window
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
