local io = require("hmm.io")
local ht = require("hmm.tree")

local M = {}

function M.reset(app)
  io.save_to_file(app)
	io.reload(app)
	ht.render(app)
end

function M.toggle_children(tree, open)
	if vim.tbl_count(tree.c) == 0 then
		return
	end
	tree.open = open
	for _, child in ipairs(tree.c) do
		M.toggle_children(child, open)
	end
end

function M.open_all(app)
	M.toggle_children(app.root, true)
	ht.render(app)
end

function M.close_all(app)
	M.toggle_children(app.root, false)
	app.active = app.root
	ht.render(app)
end

function M.toggle(app)
	if vim.tbl_count(app.active.c) == 0 then
		-- app.active = app.active.p -- a bit unexpected and annoying
		return
	end
	if app.active ~= nil then
		app.active.open = not app.active.open
	end
	ht.render(app)
	-- need to re-render as we compute positions after open
	if app.config.focus_lock then
		ht.set_offset_to_active(app)
		ht.render(app)
	end
end

function M.left(app)
	local active = app.active
	if active.p == nil then
		return
	end
	app.active = active.p
	if app.config.focus_lock then
		ht.set_offset_to_active(app)
		ht.render(app)
	end
	ht.focus_active(app)
end

function M.right(app)
	local active = app.active
	local nc = vim.tbl_count(active.c)
	if nc > 0 then
		if not active.open then
			active.open = true
			app.active = active.c[1]
			ht.render(app)
			return
		end

		-- go to nearest sibling
		local dist = 999
		local index = 1
		for i, child in ipairs(active.c) do
			local d = math.abs(child.y + child.toy - (active.y + active.toy))
			if d < dist then
				dist = d
				index = i
			end
		end
		app.active = active.c[index]
		if app.config.focus_lock then
			ht.set_offset_to_active(app)
			ht.render(app)
		end
		ht.focus_active(app)
	end
end

function M.up(app)
	-- go to parent
	local active = app.active
	if active.p == nil then
		return
	end
	if active.si == 1 then
		return
	end
	app.active = active.p.c[math.max(1, active.si - 1)]
	if app.config.focus_lock then
		ht.set_offset_to_active(app)
		ht.render(app)
	end
	ht.focus_active(app)
end

function M.down(app)
	local active = app.active
	if active.p == nil then
		return
	end
	local nc = vim.tbl_count(active.p.c)
	if active.si == nc then
		return
	end
	app.active = active.p.c[math.min(nc, active.si + 1)]
	if app.config.focus_lock then
		ht.set_offset_to_active(app)
		ht.render(app)
	end
	ht.focus_active(app)
end

function M.edit_node(app)
	vim.ui.input({}, function(text)
		if text == nil then
			return
		end
		text = vim.trim(text)
		if string.len(text) == 0 then
			return
		end
		io.set_text(app.active, text)
	end)
	ht.render(app)
	io.save_to_file(app)
end

function M.add_child(app, tree)
	local p = app.active
	if tree == nil then
		vim.ui.input({}, function(text)
			if text == nil then
				return
			end
			text = vim.trim(text)
			if string.len(text) == 0 then
				return
			end

			local node = io.new_Tree(-1, p.level + 1, text, p, app)
			table.insert(p.c, node)
			p.nc = vim.tbl_count(p.c)
			p.open = true
			app.active = node
		end)
	else
		p = app.active
		tree.p = p
		table.insert(p.c, tree)
		p.nc = vim.tbl_count(p.c)
		p.open = true
		app.active = tree
	end
	if app.config.focus_lock then
		ht.set_offset_to_active(app)
	end
	ht.render(app)
	io.save_to_file(app)
end

function M.add_sibling(app, tree)
	local sib = app.active
	if sib.p == nil then
		return
	end
	if tree == nil then
		vim.ui.input({}, function(text)
			if text == nil then
				return
			end
			text = vim.trim(text)
			if string.len(text) == 0 then
				return
			end
			local node = io.new_Tree(-1, sib.level, text, sib.p, app)

			local cc = {}
			for i = 1, sib.si, 1 do
				table.insert(cc, sib.p.c[i])
			end
			table.insert(cc, node)
			for i = sib.si + 1, vim.tbl_count(sib.p.c), 1 do
				table.insert(cc, sib.p.c[i])
			end

			sib.p.c = cc
			sib.p.nc = vim.tbl_count(cc)
			sib.p.open = true
			app.active = node
		end)
	else
		local cc = {}
		for i = 1, sib.si, 1 do
			table.insert(cc, sib.p.c[i])
		end
		table.insert(cc, tree)
		for i = sib.si + 1, vim.tbl_count(sib.p.c), 1 do
			table.insert(cc, sib.p.c[i])
		end

		tree.p = sib.p
		sib.p.c = cc
		sib.p.nc = vim.tbl_count(cc)
		sib.p.open = true
		app.active = tree
	end
	if app.config.focus_lock then
		ht.set_offset_to_active(app)
	end
	ht.render(app)
	io.save_to_file(app)
end

function M.copy_node(app)
	local tree = app.active
	app.config.clipboard = {}
	table.insert(app.config.clipboard, tree)
end

function M.paste_node_as_child(app)
	local nc = vim.tbl_count(app.config.clipboard)
	if nc == 0 then
		return
	end
	-- for now, only one assumed
	local tree = app.config.clipboard[1]
	-- avoid recursion ( shallow check )
	if tree == app.active then
		return
	end
	M.add_child(app, tree)

	-- if came from copy, then
	-- hack for deep copy
	io.reload(app)
	ht.render(app)
end

function M.paste_node_as_sibling(app)
	local nc = vim.tbl_count(app.config.clipboard)
	if nc == 0 then
		return
	end
	-- for now, only one assumed
	local tree = app.config.clipboard[1]
	-- avoid recursion ( shallow check )
	M.add_sibling(app, tree)
end

function M.delete_node(app, cut)
	local tree = app.active
	if tree.p == nil then
		return
	end
	-- cut
	if cut then
		M.copy_node(app)
	end
	-- if only child
	if vim.tbl_count(tree.p.c) == 1 then
		tree.p.c = {}
		tree.p.nc = 0
		tree.p.open = false
		app.active = tree.p
	else
		local cc = {}
		for index, child in ipairs(tree.p.c) do
			if index ~= tree.si then
				table.insert(cc, child)
			end
		end
		tree.p.c = cc
		tree.p.nc = vim.tbl_count(cc)
		app.active = tree.p.c[math.max(tree.si - 1, 1)]
	end
	io.save_to_file(app)
	ht.render(app)
end

function M.align_levels(app)
	app.config.align_levels = not app.config.align_levels
	ht.render(app)
end

function M.focus_lock(app)
	app.config.focus_lock = not app.config.focus_lock
	ht.set_offset_to_active(app)
	ht.render(app)
end

function M.undo(app)
	io.undo(app)
	ht.render(app)
end

function M.redo(app)
	io.redo(app)
	ht.render(app)
end

function M.quit(app)
	io.save_to_file(app)
	vim.cmd([[qa]])
end

return M
