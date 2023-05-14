local a = vim.api
local p = require("hmm.paper")
local M = {}

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

function M.lines_to_tree(lines)
	local tabparent = { { c = {} } }
	for _, line in ipairs(lines) do
		local tabs = vim.tbl_count(vim.split(line, "\t", {}))
		local node = { text = vim.trim(line), c = {} }
		if tabparent[tabs] ~= nil then
			table.insert(tabparent[tabs].c, node)
		end
		tabparent[tabs + 1] = node
	end
	return tabparent[1].c[1]
end

function M.lines_to_ptree(lines)
	local root = { p.new_Tree(0, 0, 0, {}, "root") }
	for _, line in ipairs(lines) do
		local tabs = vim.tbl_count(vim.split(line, "\t", {}))
		line = vim.trim(line)
		-- new_Tree(w, h, y, c, text)
		local node = p.new_Tree(a.nvim_strwidth(line), 1, tabs * 2, {}, line)
		if root[tabs] ~= nil then
			table.insert(root[tabs].c, node)
		end
		root[tabs + 1] = node
	end

	-- get the tree
	local ptree = root[1].c[1]

	-- run the algo
	p.first_walk(ptree)
	p.second_walk(ptree, 1)

	return ptree
end

function M.render_tree(tree, winbufs)
	-- create buffer
	local buf = a.nvim_create_buf(false, true)
	a.nvim_buf_set_lines(buf, 0, 1, false, { tree.text })

	-- launch and keep track of win
	local win = a.nvim_open_win(buf, true, {
		relative = "editor",
		row = 10 + math.ceil(tree.y),
		col = 10 + math.ceil(tree.x) * 5,
		width = a.nvim_strwidth(tree.text),
		height = 1,
		zindex = 20,
		style = "minimal",
	})
	table.insert(winbufs, { win, buf })

	if vim.tbl_count(tree.c) > 0 then
		for _, child in ipairs(tree.c) do
			M.render_tree(child, winbufs)
		end
	end
end

function M.destroy(winbufs)
	for _, winbuf in ipairs(winbufs) do
		a.nvim_win_close(winbuf[1], false)
		a.nvim_buf_delete(winbuf[2], { force = false })
	end
end

function M.render(win, app)
	-- Scrub
	M.destroy(app.winbufs)
	app.winbufs = {}

	-- Get the content
	local buf = a.nvim_get_current_buf()
	local lines = a.nvim_buf_get_lines(buf, 0, -1, false)
	local nlines = vim.tbl_count(lines)
	if string.len(lines[nlines]) == 0 then
		table.remove(lines)
	end

	-- create the tree
	local tree = M.lines_to_ptree(lines)

	-- render it
	M.render_tree(tree, app.winbufs)

	-- reset focus
	a.nvim_set_current_win(win)
end

return M
