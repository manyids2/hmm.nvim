local io = require("hmm.io")
local ht = require("hmm.tree")

local M = {}

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
end

function M.left(app)
	local active = app.active
	if active.p == nil then
		return
	end
	app.active = active.p
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
end

function M.add_child(app)
	local tree = app.active
	vim.ui.input({}, function(text)
		if text == nil then
			return
		end
		text = vim.trim(text)
		if string.len(text) == 0 then
			return
		end
		local node = io.new_Tree(-1, tree.level + 1, text, tree, app)
		table.insert(tree.c, node)

		tree.nc = vim.tbl_count(tree.c)
		tree.open = true
		app.active = node
	end)
	ht.render(app)
end

function M.add_sibling(app)
	local tree = app.active
	if tree.p == nil then
		return
	end
	vim.ui.input({}, function(text)
		if text == nil then
			return
		end
		text = vim.trim(text)
		if string.len(text) == 0 then
			return
		end
		local node = io.new_Tree(-1, tree.level, text, tree.p, app)

		local cc = {}
		for i = 1, tree.si, 1 do
			table.insert(cc, tree.p.c[i])
		end
		table.insert(cc, node)
		for i = tree.si + 1, vim.tbl_count(tree.p.c), 1 do
			table.insert(cc, tree.p.c[i])
		end

		tree.p.c = cc
		tree.p.nc = vim.tbl_count(cc)
		tree.p.open = true
		app.active = node
	end)
	ht.render(app)
end

return M
