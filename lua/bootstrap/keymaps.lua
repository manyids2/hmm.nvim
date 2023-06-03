-- keymaps
local function map(mode, lhs, rhs, opts)
	opts = opts or {}
	opts.silent = opts.silent ~= false
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- quit
map("n", "<C-q>", "<cmd>qa<cr>", { desc = "Quit all" })

-- For comfort options
map("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>f", "<cmd>:Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>g", "<cmd>:Telescope live_grep<cr>", { desc = "Search within files" })
map("n", "<leader>c", "<cmd>:Telescope colorscheme<cr>", { desc = "Colorscheme" })

map("n", "<leader>ds", "<cmd>:NeoTreeShowToggle<cr>", { desc = "Directory tree in split" })
map("n", "<leader>df", "<cmd>:NeoTreeFloatToggle<cr>", { desc = "Directory tree in float" })

-- splits
map("n", "+", "<cmd>set wh=999<cr><cmd>set wiw=999<cr>", { desc = "Maximize window" })
map("n", "=", "<cmd>set wh=10<cr><cmd>set wiw=10<cr><cmd>wincmd =<cr>", { desc = "Equalize windows" })

-- Move to window
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

-- Move to window
map("n", "<c-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<c-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<c-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<c-l>", "<C-w>l", { desc = "Go to right window" })

-- unmap some for now
map("n", "<enter>", "", { desc = "" })
