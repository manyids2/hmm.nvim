local ht = require("hmm.tree")

local M = {}

function M.global_keymaps(app)
	local map = vim.keymap.set

	-- pan down
	map("n", "<c-j>", function()
		app.offset.y = app.offset.y + 5
		ht.render(app)
	end, { desc = "Pan down" })

	-- pan up
	map("n", "<c-k>", function()
		app.offset.y = app.offset.y - 5
		ht.render(app)
	end, { desc = "Pan up" })

	-- pan left
	map("n", "<c-h>", function()
		app.offset.x = app.offset.x - 5
		ht.render(app)
	end, { desc = "Pan left" })

	-- pan right
	map("n", "<c-l>", function()
		app.offset.x = app.offset.x + 5
		ht.render(app)
	end, { desc = "Pan right" })

	-- reset
	map("n", "<c-0>", function()
		app.offset.x = 0
		app.offset.y = 0
		ht.render(app)
	end, { desc = "Reset root to origin" })
end

return M
