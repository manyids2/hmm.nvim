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

function M.focus_root(app)
	app.active = app.root
	ht.render(app)
	M.pan_reset(app)
end

function M.open_all(app)
	M.toggle_children(app.root, true)
	ht.render(app)
	M.pan_reset(app)
end

function M.close_all(app)
	M.toggle_children(app.root, false)
	app.active = app.root
	ht.render(app)
	M.focus_active(app)
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
	if app.config.focus_lock then
		M.focus_active(app)
	end
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
	if app.config.focus_lock then
		M.focus_active(app)
	end
end

function M.left(app)
	local active = app.active
	if active.p == nil then
		return
	end
	app.active = active.p
	ht.focus_active(app)
	if app.config.focus_lock then
		M.focus_active(app)
	end
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
	if app.config.focus_lock then
		M.focus_active(app)
	end
end

function M.pan_up(app)
	app.offset.y = app.offset.y - app.config.y_speed
	ht.render(app)
end

function M.pan_down(app)
	app.offset.y = app.offset.y + app.config.y_speed
	ht.render(app)
end

function M.pan_left(app)
	app.offset.x = app.offset.x - app.config.x_speed
	ht.render(app)
end

function M.pan_right(app)
	app.offset.x = app.offset.x + app.config.x_speed
	ht.render(app)
end

function M.pan_reset(app)
	-- disable focus_lock
	app.config.focus_lock = false
	app.offset.x = 0
	app.offset.y = 0
	ht.render(app)
end

function M.edit_node(app)
	vim.ui.input({ prompt = "  " }, function(text)
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

function M.edit_node_preserve(app)
	vim.ui.input({ prompt = "  ", default = app.active.text }, function(text)
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
		vim.ui.input({ prompt = "  " }, function(text)
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
	ht.render(app)
	io.save_to_file(app)
	if app.config.focus_lock then
		M.focus_active(app)
	end
end

function M.add_sibling(app, tree)
	local sib = app.active
	if sib.p == nil then
		return
	end
	if tree == nil then
		vim.ui.input({ prompt = "  " }, function(text)
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
	ht.render(app)
	io.save_to_file(app)
	if app.config.focus_lock then
		M.focus_active(app)
	end
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
	if app.config.focus_lock then
		M.focus_active(app)
	end
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
	if app.config.focus_lock then
		M.focus_active(app)
	end
end

function M.remove_node(app)
	M.delete_node(app, false)
end

function M.cut_node(app)
	M.delete_node(app, true)
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

	if app.config.focus_lock then
		M.focus_active(app)
	end
end

function M.move_sibling(app, up_down)
	local tree = app.active
	if tree.p == nil then
		return
	end
	local nc = vim.tbl_count(tree.p.c)
	if nc < 2 then
		return
	end

	local cc = {}
	if up_down == "up" then
		if tree.si == 1 then
			return
		end
		for i = 1, tree.si - 2 do
			table.insert(cc, tree.p.c[i])
		end
		table.insert(cc, tree.p.c[tree.si])
		table.insert(cc, tree.p.c[tree.si - 1])
		for i = tree.si + 1, nc, 1 do
			table.insert(cc, tree.p.c[i])
		end
	else
		if tree.si == nc then
			return
		end
		for i = 1, tree.si - 1 do
			table.insert(cc, tree.p.c[i])
		end
		table.insert(cc, tree.p.c[tree.si + 1])
		table.insert(cc, tree.p.c[tree.si])
		for i = tree.si + 2, nc do
			table.insert(cc, tree.p.c[i])
		end
	end

	tree.p.c = cc
	tree.p.nc = vim.tbl_count(cc)
	tree.p.open = true
end

function M.move_sibling_up(app)
	M.move_sibling(app, "up")
	ht.render(app)
end

function M.move_sibling_down(app)
	M.move_sibling(app, "down")
	ht.render(app)
end

function M.align_levels(app)
	app.config.align_levels = not app.config.align_levels
	ht.render(app)
end

function M.focus_lock(app)
	app.config.focus_lock = not app.config.focus_lock
	M.focus_active(app)
end

function M.focus_active(app)
	-- TODO: focus lock properly
	-- app.config.focus_lock = not app.config.focus_lock
	ht.set_offset_to_active(app)
	ht.render(app)
end

function M.undo(app)
	io.undo(app)
	ht.render(app)
	vim.notify(" Undo")
end

function M.redo(app)
	io.redo(app)
	ht.render(app)
	vim.notify(" Redo")
end

function M.quit(app)
	-- close the filename associated buffers and remove from files
	local state = app.state.files[app.state.current]
	io.save_to_file(state)
	ht.destroy(state)
	app.state.files[app.state.current] = nil

	-- TODO: actually want to do it in reverse order
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local bufname = vim.api.nvim_buf_get_name(buf)
		if string.len(bufname) > 0 then
			vim.api.nvim_set_current_buf(buf)
			local filetype = vim.api.nvim_exec2("echo expand('%:e')", { output = true }).output
			if filetype ~= "hmm" then
				local filename = vim.api.nvim_exec2("echo expand('%')", { output = true }).output
				app.state.current = filename .. ".hmm"
				return
			end
		end
	end
	-- close vim if nothing is left
	vim.cmd([[qa]])
end

return M
