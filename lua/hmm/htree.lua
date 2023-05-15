local a = vim.api
local M = {}

M.symbols = {
	spacer = "──────",
	bs = " ",
	bh = "─",
	bv = "│",
	bt = "╭",
	bb = "╰",
	bj = "├",
	m = 3,
}

M.Default = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

M.highlights = {
	active = a.nvim_create_namespace("active"),
	spacer = a.nvim_create_namespace("spacer"),
}

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
		nc = 0, -- number of children
		ns = 0, -- number of siblings
		si = 0, -- ith child
		-- node props
		x = 0,
		y = 0,
		w = w,
		h = 1,
		-- child props
		cx = 0,
		cy = 0,
		cw = 0,
		ch = 0,
		-- tree props
		tx = 0,
		ty = 0,
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
	ptree.open = true

	-- run the algo
	M.set_base_props(ptree, app)
	M.set_child_props(ptree, app)
	M.set_tree_props(ptree, app)

	-- position root
	ptree.x = app.offset.x
	ptree.y = app.offset.y + math.ceil(app.size.h / 2)

	return ptree
end

function M.set_base_props(tree, app)
	tree.app = app
	tree.nc = vim.tbl_count(tree.c)
	for index, child in ipairs(tree.c) do
		child.p = tree
		child.ns = tree.nc
		child.si = index
		M.set_base_props(child, app)
	end
end

function M.set_child_props(tree, app)
	local line_spacing = app.config.line_spacing

	-- compute max width across childs
	local cw = tree.w
	for _, child in ipairs(tree.c) do
		cw = math.max(cw, child.w)
	end

	-- compute height across childs assuming closed
	local ch = 0
	for _, child in ipairs(tree.c) do
		ch = ch + child.h + line_spacing
	end
	ch = math.max(0, ch - line_spacing)

	-- set for tree
	tree.cw = cw
	tree.ch = ch

	-- recurse over children
	for _, child in ipairs(tree.c) do
		M.set_child_props(child, app)
	end
end

function M.set_tree_props(tree, app)
	for _, child in ipairs(tree.c) do
		M.set_tree_props(child, app)
	end
end

function M.draw_node(tree)
	if tree.y < a.nvim_win_get_height(tree.app.win) and (tree.x + tree.w) < a.nvim_win_get_width(tree.app.win) then
		a.nvim_buf_set_text(tree.app.buf, tree.y, tree.x, tree.y, tree.x + tree.w, { " " .. tree.text .. " " })
	end
end

function M.draw_spacer(tree)
	if (tree.nc == 0) or not tree.open then
		return
	end
	local r = tree.c[1].x - tree.x - tree.w
	local m = math.max(math.ceil(2 * r / 3), 3)

	local spacer
	tree.spacers = {}

	-- Horizontal line
	local opts = {
		end_col = tree.x + tree.w + m,
		virt_text_win_col = tree.x + tree.w,
		virt_text_pos = "overlay",
		virt_text = { { string.rep(M.symbols.bh, m), "Float" } },
	}
	spacer = a.nvim_buf_set_extmark(tree.app.buf, M.highlights.spacer, tree.y, tree.x + tree.w, opts)
	table.insert(tree.spacers, spacer)

	if tree.nc == 1 then
		return
	else
		-- vertical line
		for y = 1, tree.c[tree.nc].y - tree.c[1].y - 1 do
			-- rest
			opts = {
				end_col = tree.x + tree.w + m + 1,
				virt_text_win_col = tree.x + tree.w + m,
				virt_text_pos = "overlay",
				virt_text = { { M.symbols.bv, "Float" } },
			}
			spacer =
				a.nvim_buf_set_extmark(tree.app.buf, M.highlights.spacer, tree.c[1].y + y, tree.x + tree.w + m, opts)
			table.insert(tree.spacers, spacer)
		end

		-- top child
		opts = {
			end_col = tree.x + tree.w + r,
			virt_text_win_col = tree.x + tree.w + m,
			virt_text_pos = "overlay",
			virt_text = {
				{ M.symbols.bt .. string.rep(M.symbols.bh, r - m - 1), "Float" },
			},
		}
		spacer = a.nvim_buf_set_extmark(tree.app.buf, M.highlights.spacer, tree.c[1].y, tree.x + tree.w + m, opts)
		table.insert(tree.spacers, spacer)

		-- bottom child
		opts = {
			end_col = tree.x + tree.w + r,
			virt_text_win_col = tree.x + tree.w + m,
			virt_text_pos = "overlay",
			virt_text = {
				{ M.symbols.bb .. string.rep(M.symbols.bh, r - m - 1), "Float" },
			},
		}
		spacer = a.nvim_buf_set_extmark(tree.app.buf, M.highlights.spacer, tree.c[tree.nc].y, tree.x + tree.w + m, opts)
		table.insert(tree.spacers, spacer)

		-- rest
		for index, child in ipairs(tree.c) do
			if index ~= 1 and index ~= tree.nc then
				opts = {
					end_col = tree.x + tree.w + r,
					virt_text_win_col = tree.x + tree.w + m,
					virt_text_pos = "overlay",
					virt_text = {
						{ M.symbols.bj .. string.rep(M.symbols.bh, r - m - 1), "Float" },
					},
				}
				spacer = a.nvim_buf_set_extmark(tree.app.buf, M.highlights.spacer, child.y, tree.x + tree.w + m, opts)
				table.insert(tree.spacers, spacer)
			end
		end
	end
end

function M.clear_win_buf(win, buf)
	local size = { w = a.nvim_win_get_width(win), h = a.nvim_win_get_height(win) }
	local replacement = { string.rep(" ", size.w) }
	for i = 0, size.h, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end
end

function M.focus_active(app)
	local active = app.active
	a.nvim_set_current_buf(app.buf)
	a.nvim_set_current_win(app.win)
	a.nvim_win_set_cursor(app.win, { active.y + 1, active.x })
	a.nvim_buf_clear_namespace(app.buf, M.highlights.active, 0, -1)
	a.nvim_buf_add_highlight(app.buf, M.highlights.active, "IncSearch", active.y, active.x, active.x + active.w)
end

function M.first_walk(tree, config)
	if not tree.open then
		return
	end

	M.adjust_siblings(tree, config)
	if vim.tbl_count(tree.c) > 0 then
		local top = -math.floor(tree.ch / 2)
		for _, child in ipairs(tree.c) do
			child.x = tree.x + tree.cw + a.nvim_strwidth(M.symbols.spacer)
			child.y = tree.y + top
			top = top + config.line_spacing + child.h
			M.first_walk(child, config)
		end
	end
end

function M.adjust_siblings(tree, config)
	if not tree.open then
		return
	end
	if vim.tbl_count(tree.c) == 0 then
		return
	end
	if tree.p == nil then
		return
	end

	-- adjust siblings
	-- local ls = config.line_spacing
	for _, sibling in ipairs(tree.p.c) do
		local offset = { x = 0, y = 0 }
		if sibling.si < tree.si then
			offset = { x = 0, y = -math.floor(tree.ch / 2) }
			M.move_tree(sibling, offset)
		elseif sibling.si > tree.si then
			offset = { x = 0, y = math.floor(tree.ch / 2) }
			M.move_tree(sibling, offset)
		end
	end
end

function M.move_tree(tree, offset)
	tree.x = tree.x + offset.x
	tree.y = tree.y + offset.y
	if not tree.open then
		return
	end
	if vim.tbl_count(tree.c) > 0 then
		for _, child in ipairs(tree.c) do
			M.move_tree(child, offset)
		end
	end
end

function M.render_tree(tree)
	M.draw_node(tree)
	if not tree.open then
		return
	end

	if vim.tbl_count(tree.c) > 0 then
		M.draw_spacer(tree)
		for _, child in ipairs(tree.c) do
			M.render_tree(child)
		end
	end
end

function M.render(app)
	-- clear screen
	M.clear_win_buf(app.win, app.buf)

	-- set real x, y, h, w of tree
	M.first_walk(app.tree, app.config)

	-- run recursive render on root from scratch
	M.render_tree(app.tree)
	M.focus_active(app)
end

return M
