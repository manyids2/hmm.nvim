local ht = require("hmm.tree")
local hh = require("hmm.help")
local he = require("hmm.export")
local ax = require("hmm.actions")

local M = {}

function M.map(mode, lhs, rhs, desc, data, buf)
	vim.keymap.set(mode, lhs, function()
		rhs(data)
	end, { desc = desc, buffer = buf })
end

function M.buffer_keymaps(state, app, buf)
	-- quit, help, export
	M.map("n", "q", ax.quit, "quit", app, buf)
	M.map("n", "?", hh.open_help, "help", app, buf)
	M.map("n", "z", hh.open_config, "config", app, buf)
	M.map("n", "<C-x>", he.open_export, "export", app, buf)

	-- toggle
	M.map("n", "<space>", ax.toggle, "toggle", state, buf)
	M.map("n", "b", ax.open_all, "open all", state, buf)
	M.map("n", "B", ax.close_all, "close all", state, buf)

	-- navigation
	M.map("n", "k", ax.up, "up", state, buf)
	M.map("n", "j", ax.down, "down", state, buf)
	M.map("n", "h", ax.left, "left", state, buf)
	M.map("n", "l", ax.right, "right", state, buf)
	M.map("n", "<up>", ax.up, "up", state, buf)
	M.map("n", "<down>", ax.down, "down", state, buf)
	M.map("n", "<left>", ax.left, "left", state, buf)
	M.map("n", "<right>", ax.right, "right", state, buf)

	-- pan
	M.map("n", "<M-k>", ax.pan_up, "pan up", state, buf)
	M.map("n", "<M-j>", ax.pan_down, "pan down", state, buf)
	M.map("n", "<M-h>", ax.pan_left, "pan left", state, buf)
	M.map("n", "<M-l>", ax.pan_right, "pan right", state, buf)
	M.map("n", "0", ax.pan_reset, "pan reset", state, buf)

	-- focus
	M.map("n", "~", ax.focus_root, "focus root", state, buf)
	M.map("n", "m", ax.focus_root, "focus root", state, buf)
	M.map("n", "c", ax.focus_active, "focus active", state, buf)
	M.map("n", "C", ax.focus_lock, "focus lock", state, buf)

	-- edit
	M.map("n", "e", ax.edit_node_preserve, "edit node", state, buf)
	M.map("n", "s", ax.edit_node_preserve, "edit node", state, buf)
	M.map("n", "a", ax.edit_node_preserve, "edit node", state, buf)
	M.map("n", "i", ax.edit_node_preserve, "edit node", state, buf)
	M.map("n", "E", ax.edit_node, "edit node from blank", state, buf)
	M.map("n", "S", ax.edit_node, "edit node from blank", state, buf)
	M.map("n", "A", ax.edit_node, "edit node from blank", state, buf)
	M.map("n", "I", ax.edit_node, "edit node from blank", state, buf)

	-- add
	M.map("n", "<enter>", ax.add_sibling, "add sibling", state, buf)
	M.map("n", "o", ax.add_sibling, "add sibling", state, buf)
	M.map("n", "<tab>", ax.add_child, "add child", state, buf)
	M.map("n", "O", ax.add_child, "add child", state, buf)

	-- move
	M.map("n", "K", ax.move_sibling_up, "move up", state, buf)
	M.map("n", "J", ax.move_sibling_down, "move down", state, buf)

	-- copy node -- need to make deep copy
	-- or check if was copied, then write
	-- to file and reload, so expensive for now
	M.map("n", "y", ax.copy_node, "copy node", state, buf)
	M.map("n", "d", ax.cut_node, "cut node", state, buf)
	M.map("n", "<delete>", ax.delete_node, "delete node", state, buf)
	M.map("n", "p", ax.paste_node_as_child, "paste node as child", state, buf)
	M.map("n", "P", ax.paste_node_as_sibling, "paste node as sibling", state, buf)

	-- manual refreshes
	-- M.map("n", "<esc>", ht.render, "render", state, buf)
	M.map("n", "<c-s>", ax.reset, "reset", state, buf)

	-- undo, redo
	M.map("n", "u", ax.undo, "undo", state, buf)
	M.map("n", "<c-r>", ax.redo, "redo", state, buf)

	-- debug
	M.map("n", "t", function()
		local active = state.active
		for key, value in pairs(active) do
			if key ~= "c" then -- children is too long
				print(key, value)
			end
		end
	end, { desc = "Debug" })
end

return M
