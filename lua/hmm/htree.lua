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
		-- child props
		cw = 0,
		ch = 0,
		-- tree props
		tw = w,
		th = 1,
	}
end

function M.print_tree(t)
	print(string.format("index: %d; level: %d; text: %s", t.index, t.level, t.text))
	print(string.format("nc: %d; ns: %d; si: %d", t.nc, t.ns, t.si))
	print(string.format(" x: %d;  y: %d;  w: %d;  h: %d", t.x, t.y, t.w, t.h))
	print(string.format("cx: %d; cy: %d; cw: %d; ch: %d", t.cx, t.cy, t.cw, t.ch))
	print(string.format("tx: %d; ty: %d; tw: %d; th: %d", t.tx, t.ty, t.tw, t.th))
	print(string.format("spacer: %d", string.len(M.symbols.spacer)))
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
		tree.ns = tree.p.nc
		-- can already set x
		tree.x = parent.x + config.margin
	end
	-- only continue if open
	if tree.open then
		tree.nc = vim.tbl_count(tree.c)
	else
		tree.nc = 0
    -- reset
    tree.ch = 0
    tree.cw = 0
    tree.th = 1
    tree.tw = tree.w
		return
	end
	-- recurse
	local ch = 0
	local cw = 0
	for index, child in ipairs(tree.c) do
		M.set_props(child, index, tree, app)
		ch = ch + child.ch + config.line_spacing
		cw = cw + child.cw + config.margin
	end
	-- children relevant props
	tree.ch = ch - config.line_spacing
	tree.cw = cw
	-- tree relevant props
	tree.th = ch
	tree.tw = tree.cw + config.margin + tree.w
end

return M
