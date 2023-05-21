local ht = require("hmm.tree")
local hh = require("hmm.help")
local he = require("hmm.export")
local ax = require("hmm.actions")

local M = {}

function M.map(mode, lhs, rhs, desc, app)
	vim.keymap.set(mode, lhs, function()
		rhs(app)
	end, { desc = desc, buffer = app.buf })
end

function M.buffer_keymaps(app)
	local map = vim.keymap.set
	-- quit, help, export
	M.map("n", "q", ax.quit, "quit", app)
	M.map("n", "?", hh.open_help, "help", app)
	M.map("n", "z", hh.open_config, "config", app)
	M.map("n", "<C-x>", he.open_export, "export", app)

	-- toggle
	M.map("n", "<space>", ax.toggle, "toggle", app)
	M.map("n", "b", ax.open_all, "open all", app)
	M.map("n", "B", ax.close_all, "close all", app)

	-- navigation
	M.map("n", "k", ax.up, "up", app)
	M.map("n", "j", ax.down, "down", app)
	M.map("n", "h", ax.left, "left", app)
	M.map("n", "l", ax.right, "right", app)
	M.map("n", "<up>", ax.up, "up", app)
	M.map("n", "<down>", ax.down, "down", app)
	M.map("n", "<left>", ax.left, "left", app)
	M.map("n", "<right>", ax.right, "right", app)

	-- pan
	M.map("n", "<M-k>", ax.pan_up, "pan up", app)
	M.map("n", "<M-j>", ax.pan_down, "pan down", app)
	M.map("n", "<M-h>", ax.pan_left, "pan left", app)
	M.map("n", "<M-l>", ax.pan_right, "pan right", app)
	M.map("n", "0", ax.pan_reset, "pan reset", app)

	-- focus
	M.map("n", "~", ax.focus_root, "focus root", app)
	M.map("n", "m", ax.focus_root, "focus root", app)
	M.map("n", "c", ax.focus_active, "focus active", app)
	M.map("n", "C", ax.focus_lock, "focus lock", app)

	-- edit
	M.map("n", "e", ax.edit_node_preserve, "edit node", app)
	M.map("n", "s", ax.edit_node_preserve, "edit node", app)
	M.map("n", "a", ax.edit_node_preserve, "edit node", app)
	M.map("n", "i", ax.edit_node_preserve, "edit node", app)
	M.map("n", "E", ax.edit_node, "edit node from blank", app)
	M.map("n", "S", ax.edit_node, "edit node from blank", app)
	M.map("n", "A", ax.edit_node, "edit node from blank", app)
	M.map("n", "I", ax.edit_node, "edit node from blank", app)

	-- add
	M.map("n", "<enter>", ax.add_sibling, "add sibling", app)
	M.map("n", "o", ax.add_sibling, "add sibling", app)
	M.map("n", "<tab>", ax.add_child, "add child", app)
	M.map("n", "O", ax.add_child, "add child", app)

	-- move
	M.map("n", "K", ax.move_sibling_up, "move up", app)
	M.map("n", "J", ax.move_sibling_down, "move down", app)

	-- copy node -- need to make deep copy
	-- or check if was copied, then write
	-- to file and reload, so expensive for now
	M.map("n", "y", ax.copy_node, "copy node", app)
	M.map("n", "d", ax.cut_node, "cut node", app)
	M.map("n", "<delete>", ax.delete_node, "delete node", app)
	M.map("n", "p", ax.paste_node_as_child, "paste node as child", app)
	M.map("n", "P", ax.paste_node_as_sibling, "paste node as sibling", app)

	-- manual refreshes
	M.map("n", "<esc>", ht.render, "render", app)
	M.map("n", "<c-s>", ax.reset, "reset", app)

	-- undo, redo
	M.map("n", "u", ax.undo, "undo", app)
	M.map("n", "<c-r>", ax.redo, "redo", app)

	-- debug
	map("n", "t", function()
		print(app.active.tw, app.active.th)
	end, { desc = "Debug" })
end

return M
