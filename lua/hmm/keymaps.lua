local io = require("hmm.io")
local ht = require("hmm.tree")

local M = {}

function M.global_keymaps(app)
	local map = vim.keymap.set

	-- focus active
	map("n", "f", function()
		io.focus_active(app)
	end, { desc = "Focus active node" })

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
end

return M
