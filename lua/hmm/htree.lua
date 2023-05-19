local M = {}

function M.new_Tree(index, level, text)
	local w = string.len(text) + 2
	return {
		-- our custom metada
		index = index,
		level = level,
		text = text,
		open = false,
		-- ref to app
		app = nil,
		-- base props
		p = nil, -- parent
		c = {}, -- children
		nc = 0, -- number of OPEN children
		ns = 0, -- number of siblings
		si = 0, -- ith child
		-- node props
		x = 0,
		y = 0,
		w = w,
		h = 1,
		o = 0,
		-- child props
		cw = 0,
		ch = 1,
		-- tree props
		tw = w,
		th = 1,
		ty = 0,
	}
end

function M.print_tree(t)
	print(string.format("index: %d; level: %d; text: %s", t.index, t.level, t.text))
	print(string.format("open: %s; nc: %d", tostring(t.open), t.nc))
	print(string.format("ns: %d; si: %d", t.ns, t.si))
	print(string.format("cw: %d; ch: %d", t.cw, t.ch))
	print(string.format("tw: %d; th: %d; o %d", t.tw, t.th, t.o))
	print(string.format(" x: %d;  y: %d;  w: %d;  h: %d", t.x, t.y, t.w, t.h))
end

function M.tree_to_lines(tree, level)
	if level == nil then
		level = 0
	end
	local lines = { string.rep("\t", level) .. tree.text }
	if vim.tbl_count(tree.c) > 0 then
		for _, child in ipairs(tree.c) do
			local clines = M.tree_to_lines(child, level + 1)
			if clines ~= nil then
				for _, line in ipairs(clines) do
					table.insert(lines, line)
				end
			end
		end
	end
	return lines
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
		if level <= app.config.initial_depth then
			node.open = true
		end
		table.insert(nodes, node)
		if root[level] ~= nil then
			table.insert(root[level].c, node)
		end
		root[level + 1] = node
	end

	-- get the tree
	local ptree = root[1].c[1]

	M.set_props(ptree, 1, nil, app)

	return ptree
end

function M.set_props(tree, si, parent, app)
	-- parent relevant props
	tree.app = app
	local config = app.config
	if parent ~= nil then
		tree.p = parent
		tree.si = si
		tree.ns = vim.tbl_count(tree.p.c)
		-- can already set x for layered tree
		tree.x = parent.x + parent.w + config.margin
	end
	-- only continue if open
	if not tree.open then
		tree.nc = 0
		-- reset
		tree.ch = 1 + config.line_spacing
		tree.cw = 0
		tree.th = 1 + config.line_spacing
		tree.tw = tree.w
		tree.o = 0
		return
	end
	tree.nc = vim.tbl_count(tree.c)
	-- recurse
	local ch = 0
	local cw = 0
	for index, child in ipairs(tree.c) do
		M.set_props(child, index, tree, app)
		ch = ch + child.th
		cw = cw + child.cw + config.margin
	end
	-- children relevant props
	tree.ch = ch
	tree.cw = cw
	-- tree relevant props
	tree.th = ch
	tree.tw = tree.cw + config.margin + tree.w
	tree.o = 0
end

function M.set_y(tree, config)
	local bottom = tree.y
	for _, child in ipairs(tree.c) do
		child.y = bottom
		M.set_y(child, config)
		bottom = bottom + child.th
	end
	tree.o = math.floor(tree.th / 2) - 1
end

function M.delete_node(tree, app)
	if tree.p == nil then
		return
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
end

function M.add_child(tree, app)
	vim.ui.input({}, function(text)
		if text == nil then
			return
		end
		text = vim.trim(text)
		if string.len(text) == 0 then
			return
		end
		local node = M.new_Tree(-1, tree.level + 1, text)
		node.app = app
		table.insert(tree.c, node)

		tree.nc = vim.tbl_count(tree.c)
		tree.open = true
		app.active = node
	end)
	M.set_props(app.tree, 1, nil, app)
end

function M.add_sibling(tree, app)
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
		local node = M.new_Tree(-1, tree.level, text)
		node.app = app

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
	M.set_props(app.tree, 1, nil, app)
end

function M.move_sibling(tree, up_down, app)
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

	M.set_props(app.tree, 1, nil, app)
end

return M
