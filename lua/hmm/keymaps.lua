local ht = require("hmm.tree")
local ax = require("hmm.actions")

local M = {}

function M.global_keymaps(app)
	local map = vim.keymap.set

	-- toggle
	map("n", "<space>", function()
		ax.toggle(app)
	end, { desc = "toggle" })

	-- open all
	map("n", "b", function()
		ax.open_all(app)
	end, { desc = "open all" })

	-- close all
	map("n", "B", function()
		ax.close_all(app)
	end, { desc = "close all" })

	-- down
	map("n", "j", function()
		ax.down(app)
	end, { desc = "down" })

	-- up
	map("n", "k", function()
		ax.up(app)
	end, { desc = "up" })

	-- left
	map("n", "h", function()
		ax.left(app)
	end, { desc = "left" })

	-- right
	map("n", "l", function()
		ax.right(app)
	end, { desc = "right" })

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

	-- align levels
	map("n", "|", function()
		ax.align_levels(app)
	end, { desc = "align levels" })

	-- edit
	map("n", "e", function()
		ax.edit_node(app)
	end, { desc = "edit" })

	-- add child
	map("n", "<tab>", function()
		ax.add_child(app)
	end, { desc = "add child" })

	-- add sibling
	map("n", "<enter>", function()
		ax.add_sibling(app)
	end, { desc = "add sibling" })
end

return M
