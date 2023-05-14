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

function M.new_Tree(index, level, text)
	local w = a.nvim_strwidth(text) + 2
	return {
		-- our custom metada
		index = index,
		level = level,
		text = text,
		open = false,
		active = false,
		-- ref to app
		app = nil,
		-- base props
		p = nil, -- parent
		c = {}, -- children
		nc = 0, -- number of children
		ci = 0, -- ith child
		-- refs to siblings
		sp = nil, -- prev sibling
		sn = nil, -- next sibling
		sf = nil, -- first sibling
		sl = nil, -- last sibling
		-- node props
		x = 0,
		y = 0,
		w = w,
		h = 1,
		-- sibling props
		sx = 0,
		sy = 0,
		sw = w,
		sh = 1,
		-- tree props
		tx = 0,
		ty = 0,
		tw = w,
		th = 1,
	}
end

function M.lines_to_htree(lines, app)
	local nlines = vim.tbl_count(lines)
	if string.len(lines[nlines]) == 0 then
		table.remove(lines)
	end

	local root = { M.new_Tree(0, 0, "root") }
	local nodes = {}
	for index, line in ipairs(lines) do
		local level = vim.tbl_count(vim.split(line, "\t", {}))
		line = vim.trim(line)
		local node = M.new_Tree(index, level, line)
		table.insert(nodes, node)
		if root[level] ~= nil then
			table.insert(root[level].c, node)
		end
		root[level + 1] = node
	end

	-- get the tree
	local ptree = root[1].c[1]
	ptree.open = true
	ptree.active = true

	-- position root
	ptree.x = app.offset.x
	ptree.y = app.offset.y + math.ceil(app.size.h / 2)

	-- run the algo
	M.set_base_props(ptree, app)
	M.set_sibling_props(ptree, app)

	return ptree
end

function M.set_base_props(tree, app)
	tree.app = app
	tree.nc = vim.tbl_count(tree.c)
	for index, child in ipairs(tree.c) do
		child.p = tree
		child.ci = index
		M.set_base_props(child, app)
	end
end

function M.set_sibling_props(tree, app)
	local line_spacing = app.config.line_spacing
	if tree.p == nil then
		return
	end

	-- Set width to max across siblings
	local sw = 0
	for _, child in ipairs(tree.p.c) do
		sw = math.max(sw, child.w)
	end

	for _, child in ipairs(tree.c) do
		child.sw = sw
		M.set_sibling_props(child, app)
	end

	-- Set height to sum over children
	local sh = 0
	for _, child in ipairs(tree.p.c) do
		sh = sh + child.h + line_spacing
	end
	sh = sh - line_spacing
end

function M.render_tree(tree)
	-- draw on buffer
	a.nvim_buf_set_text(tree.app.buf, tree.y, tree.x, tree.y, tree.x + tree.w, { tree.text })

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
	-- toggle node
	vim.keymap.set("n", "<space>", function()
		tree.open = not tree.open
		M.render(tree.app)
	end, { desc = "Open/Close", buffer = tree.buf })
end

function M.clear_win_buf(win, buf)
	local size = { w = a.nvim_win_get_width(win), h = a.nvim_win_get_height(win) }
	local replacement = { string.rep(" ", size.w) }
	for i = 0, size.h, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end
	a.nvim_win_set_cursor(win, { 1, 0 })
end

function M.render(app)
	-- clear screen
	M.clear_win_buf(app.win, app.buf)

	-- run recursive render on root from scratch
	M.render_tree(app.tree)
end

return M
