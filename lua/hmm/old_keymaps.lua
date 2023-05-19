local h = require("hmm.help")
local t = require("hmm.htree")
local r = require("hmm.render")

local M = {}

function M.open_children(tree)
	if vim.tbl_count(tree.c) == 0 then
		return
	end
	tree.open = true
	for _, child in ipairs(tree.c) do
		M.open_children(child)
	end
end

function M.open_all(app)
	M.open_children(app.tree)
	r.render(app)
end

function M.toggle(app)
	if vim.tbl_count(app.active.c) == 0 then
		app.active = app.active.p
	end
	if app.active ~= nil then
		app.active.open = not app.active.open
	end
	r.render(app)
end

function M.left(app)
	local active = app.active
	if active.p == nil then
		return
	end
	app.active = active.p
	r.focus_active(app)
end

function M.right(app)
	local active = app.active
	if not active.open and vim.tbl_count(active.c) > 0 then
		active.open = true
		r.render(app)
	end
	if active.nc ~= 0 then
		local dist = 999
		local index = 1
		for i, child in ipairs(active.c) do
			local d = math.abs(child.y - (active.y + active.o))
			if d < dist then
				dist = d
				index = i
			end
		end
		app.active = active.c[index]
		r.focus_active(app)
	end
end

function M.up(app)
	local active = app.active
	if active.p == nil then
		return
	end
	if active.si == 1 then
		return
	end
	app.active = active.p.c[math.max(1, active.si - 1)]
	r.focus_active(app)
end

function M.down(app)
	local active = app.active
	if active.p == nil then
		return
	end
	if active.si == active.ns then
		return
	end
	app.active = active.p.c[math.min(active.ns, active.si + 1)]
	r.focus_active(app)
end

function M.copy(app)
	local active = app.active
	t.copy_node(active, app)
	r.render(app)
end

function M.delete(app, to_clipboard)
	local active = app.active
	t.delete_node(active, app, to_clipboard)
	r.render(app)
end

function M.edit_node(app, blank)
	local active = app.active
	if blank then
		t.edit_node(active, app, { default = "" })
	else
		t.edit_node(active, app, { default = active.text })
	end
	r.render(app)
end

function M.add_child(app, from_clipboard)
	local active = app.active
	active.open = true
	t.add_child(active, app, from_clipboard)
	r.render(app)
end

function M.add_sibling(app)
	local active = app.active
	t.add_sibling(active, app)
	r.render(app)
end

function M.move_sibling(app, up_down)
	local active = app.active
	t.move_sibling(active, up_down, app)
	r.render(app)
end

function M.save(app)
  r.render(app)
	t.save_to_file(app)
end

function M.undo(app)
	t.undo(app)
	r.render(app)
end

function M.redo(app)
	t.redo(app)
	r.render(app)
end

function M.global_keymaps(app)
	local map = vim.keymap.set

	-- focus active
	map("n", "f", function()
		r.focus_active(app)
	end, { desc = "Focus" })

	-- save to source
	map("n", "s", function()
		M.save(app)
	end, { buffer = app.buf, desc = "Save" })

	-- quit
	map("n", "<esc>", function()
		M.save(app)
		vim.cmd([[qa]])
	end, { buffer = app.buf, desc = "Quit" })

	-- save to source
	map("n", "q", function()
		M.save(app)
		vim.cmd([[qa]])
	end, { buffer = app.buf, desc = "Quit" })

	-- toggle node
	map("n", "<space>", function()
		M.toggle(app)
	end, { buffer = app.buf, desc = "Toggle" })

	-- navigation
	map("n", "k", function()
		M.up(app)
	end, { buffer = app.buf, desc = "Up" })

	map("n", "<up>", function()
		M.up(app)
	end, { buffer = app.buf, desc = "Up" })

	map("n", "j", function()
		M.down(app)
	end, { buffer = app.buf, desc = "Down" })

	map("n", "<down>", function()
		M.down(app)
	end, { buffer = app.buf, desc = "Down" })

	map("n", "h", function()
		M.left(app)
	end, { buffer = app.buf, desc = "Left" })

	map("n", "<left>", function()
		M.left(app)
	end, { buffer = app.buf, desc = "Left" })

	map("n", "l", function()
		M.right(app)
	end, { buffer = app.buf, desc = "Right" })

	map("n", "<right>", function()
		M.right(app)
	end, { buffer = app.buf, desc = "Right" })

	map("n", "<delete>", function()
		M.delete(app, false)
	end, { buffer = app.buf, desc = "Delete" })

	map("n", "d", function()
		M.delete(app, true)
	end, { buffer = app.buf, desc = "Cut" })

	map("n", "y", function()
		M.copy(app)
	end, { buffer = app.buf, desc = "Copy" })

	map("n", "<tab>", function()
		M.add_child(app, false)
		M.save(app)
	end, { buffer = app.buf, desc = "Add child" })

	map("n", "p", function()
		if app.clipboard[vim.tbl_count(app.clipboard)] == app.active then
			return
		end
		M.add_child(app, true)
		M.save(app)
		t.reload(app)
		r.render(app)
	end, { buffer = app.buf, desc = "Paste as child" })

	map("n", "<enter>", function()
		M.add_sibling(app)
		M.save(app)
	end, { buffer = app.buf, desc = "Add sibling" })

	map("n", "e", function()
		M.edit_node(app, false)
		M.save(app)
	end, { buffer = app.buf, desc = "Edit" })

	map("n", "i", function()
		M.edit_node(app, false)
		M.save(app)
	end, { buffer = app.buf, desc = "Edit" })

	map("n", "a", function()
		M.edit_node(app, false)
		M.save(app)
	end, { buffer = app.buf, desc = "Edit" })

	map("n", "E", function()
		M.edit_node(app, true)
		M.save(app)
	end, { buffer = app.buf, desc = "Edit from blank" })

	map("n", "I", function()
		M.edit_node(app, true)
		M.save(app)
	end, { buffer = app.buf, desc = "Edit from blank" })

	map("n", "A", function()
		M.edit_node(app, true)
		M.save(app)
	end, { buffer = app.buf, desc = "Edit from blank" })

	map("n", "K", function()
		M.move_sibling(app, "up")
	end, { buffer = app.buf, desc = "Move up" })

	map("n", "J", function()
		M.move_sibling(app, "down")
	end, { buffer = app.buf, desc = "Move down" })

	map("n", "b", function()
		M.open_all(app)
	end, { buffer = app.buf, desc = "Open all" })

	map("n", "?", function()
		h.open_help(app)
	end, { buffer = app.buf, desc = "Open help" })

	map("n", "u", function()
		M.undo(app)
	end, { buffer = app.buf, desc = "Undo" })

	map("n", "<c-r>", function()
		M.redo(app)
	end, { buffer = app.buf, desc = "Redo" })

	map("n", "t", function()
		vim.cmd([[:messages clear]])
		t.print_tree(app.active)
		vim.cmd([[:messages]])
	end, { buffer = app.buf, desc = "Print tree" })

	map("n", "~", function()
		vim.cmd([[:messages]])
	end, { buffer = app.buf, desc = "Messages" })
end

return M
