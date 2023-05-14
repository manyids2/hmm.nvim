local a = vim.api
local M = {}

function M.wrap_text(text, max_leaf_node_width)
	local buf = a.nvim_create_buf(false, true)
	a.nvim_buf_set_lines(buf, 0, 1, false, { text })
	a.nvim_buf_set_option(buf, "textwidth", max_leaf_node_width)
	a.nvim_buf_call(buf, function()
		vim.cmd([[gVgggq]])
	end)
	P(a.nvim_buf_get_lines(buf, 0, -1, false))
end

function M.new_Tree(index, tabs, text, parent)
	return {
		-- our custom metada
		index = index,
		tabs = tabs,
		text = text,
		open = false,
		active = false,
		-- win, buf
		win = nil,
		buf = nil,
		-- hidden flag
		hidden = false,
		-- predefined properties
		p = parent, -- parent
		c = {}, -- children
		cs = 0, -- count of children
		x = tabs * 10,
		y = 5, -- initial height
		w = a.nvim_strwidth(text) + 2, -- width
		h = 1, -- height
		tw = a.nvim_strwidth(text) + 2, -- width of tree
		th = 1, -- height of tree
	}
end

function M.lines_to_htree(lines, offset, size)
	local root = { M.new_Tree(0, 0, "root", nil) }
	local nodes = {}
	for index, line in ipairs(lines) do
		local tabs = vim.tbl_count(vim.split(line, "\t", {}))
		line = vim.trim(line)
		local node = M.new_Tree(index, tabs, line, root[tabs])
		table.insert(nodes, node)
		if root[tabs] ~= nil then
			table.insert(root[tabs].c, node)
		end
		root[tabs + 1] = node
	end

	-- get the tree
	local ptree = root[1].c[1]
	ptree.open = true
	ptree.active = true

	ptree.x = offset.x
	ptree.y = offset.y + math.ceil(size.h / 2)

	-- -- run the algo
	M.set_cs(ptree)
	M.set_hw(ptree)

	return ptree
end

function M.set_cs(tree)
	tree.cs = vim.tbl_count(tree.c)
	for _, child in ipairs(tree.c) do
		M.set_cs(child)
	end
end

function M.set_hw(tree)
	if vim.tbl_count(tree.c) == 0 then
		return
	end

	local size = { h = 0, w = 0 }
	for _, child in ipairs(tree.c) do
		M.set_hw(child)
		size.h = size.h + child.th
		size.w = math.max(size.w, child.tw)
	end
	tree.th = size.h
	tree.tw = size.w
end

function M.open_children(tree)
	tree.open = true
	for _, child in ipairs(tree.c) do
		child.open = true
	end
end

function M.close_tree(tree)
	tree.open = false
	if tree.win ~= nil then
		a.nvim_win_close(tree.win, false)
		tree.win = nil
	end
	if tree.buf ~= nil then
		a.nvim_buf_delete(tree.buf, { force = false })
		tree.buf = nil
	end
	for _, child in ipairs(tree.c) do
		M.close_tree(child)
	end
end

function M.toggle_node(tree)
	tree.open = not tree.open
	if vim.tbl_count(tree.c) == 0 then
		return
	end

	if not tree.open then
		M.close_tree(tree)
	end

	M.render_tree(tree)
end

function M.render_tree(tree)
	if tree.buf == nil then
		tree.buf = a.nvim_create_buf(false, true)
		a.nvim_buf_set_lines(tree.buf, 0, 1, false, { " " .. tree.text .. " " })
	end

	if tree.win == nil then
		tree.win = a.nvim_open_win(tree.buf, true, {
			relative = "editor",
			row = math.ceil(tree.y),
			col = 2 + math.ceil(tree.x),
			width = tree.w,
			height = tree.h,
			zindex = 20,
			style = "minimal",
		})
	else
		a.nvim_win_set_config(tree.win, {
			relative = "editor",
			row = math.ceil(tree.y),
			col = 2 + math.ceil(tree.x),
			width = tree.w,
			height = tree.h,
		})
	end

	M.keymaps(tree)

	if not tree.open then
		return
	end

	if vim.tbl_count(tree.c) > 0 then
		for _, child in ipairs(tree.c) do
			M.render_tree(child)
		end
	end
end

function M.keymaps(tree)
	-- expand node
	vim.keymap.set("n", "<space>", function()
		M.toggle_node(tree)
	end, { desc = "Open/Close", buffer = tree.buf })

	-- right
	vim.keymap.set("n", "l", function()
		vim.notify("right")
		if vim.tbl_count(tree.c) == 0 then
			return
		end
		if not tree.open then
			M.toggle_node(tree)
		end
		a.nvim_set_current_win(tree.c[1].win)
	end, { desc = "First child", buffer = tree.buf })

	-- left
	vim.keymap.set("n", "h", function()
		if tree.p.win ~= nil then
			a.nvim_set_current_win(tree.p.win)
		end
	end, { desc = "Parent", buffer = tree.buf })
end

function M.destroy_tree(tree)
	if vim.tbl_count(tree.c) > 0 then
		for _, child in ipairs(tree.c) do
			M.destroy_tree(child)
		end
	end
	if tree.win ~= nil then
		a.nvim_win_close(tree.win, false)
	end
	if tree.buf ~= nil then
		a.nvim_buf_delete(tree.buf, { force = false })
	end
end

function M.render(app)
	-- Destroy current
	M.destroy_tree(app.tree)

	-- Get the content
	local lines = a.nvim_buf_get_lines(app.buf, 0, -1, false)
	local nlines = vim.tbl_count(lines)
	if string.len(lines[nlines]) == 0 then
		table.remove(lines)
	end

	-- create the tree
	app.tree = M.lines_to_htree(lines, app.offset, app.size)

	-- render it
	M.render_tree(app.tree)
	P(a.nvim_list_wins())
end

return M
