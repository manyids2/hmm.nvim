local a = vim.api

local M = {}

function M.new_Tree(index, level, text, app)
	local state = M.get_state_from_text(text)
	return {
		-- our custom metada
		app = app,
		index = index,
		level = level,
		text = text,
		open = state.open,
		active = state.active,
		-- base props
		p = nil, -- parent
		c = {}, -- children
		nc = 0, -- number of OPEN children
		ns = 0, -- number of siblings
		si = 0, -- ith child
		-- node props
		x = 0,
		y = 0,
		w = state.w,
		h = state.h,
		-- child props
		cx = state.w + 1,
		cy = 0,
		cw = 0,
		ch = 0,
		-- tree props
		tx = 0,
		ty = 0,
		tox = 0,
		toy = 0,
		tw = state.w,
		th = state.h,
	}
end

function M.get_state_from_text(text)
	local w = string.len(text)
	local active = false
	local open = false
	if string.sub(text, w - 2, w - 2) == "|" then
		if string.sub(text, w - 1, w - 1) == "1" then
			open = true
		end
		if string.sub(text, w, w) == "1" then
			active = true
		end
		text = string.sub(text, 1, w - 3)
		w = string.len(text)
	end
	return { h = 1, w = w, active = active, open = open }
end

function M.get_text_for_state(tree)
	local oo = tree.open and "1" or "0"
	local aa = tree.app.active == tree and "1" or "0"
	return oo .. aa
end

function M.tree_to_lines(tree, level)
	-- append state to line
	local oa = M.get_text_for_state(tree)
	local lines = { string.rep("\t", level) .. tree.text .. "|" .. oa }

	-- recursively make the tree
	if vim.tbl_count(tree.c) > 0 then
		for _, child in ipairs(tree.c) do
			-- recursion
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

function M.lines_to_tree(lines, app)
	-- initialize root ( will be discarded )
	local root = { M.new_Tree(0, 0, "root", app) }

	-- one node for each line
	for index, line in ipairs(lines) do
		line = vim.trim(line)
		if string.len(line) == 0 then
			-- get indent level
			local level = vim.tbl_count(vim.split(line, "\t", {}))

			-- set up new node
			local node = M.new_Tree(index, level, line, app)

			-- open as per config
			if level <= app.config.initial_depth then
				node.open = true
			end

			-- mark active
			if node.active then
				app.active = node
			end

			-- insert into tree with proper parent
			if root[level] ~= nil then
				table.insert(root[level].c, node)
			end

			-- set as parent for current level
			root[level + 1] = node
		end
	end

	-- if empty tree, then create a node
	if vim.tbl_count(root[1].c) == 0 then
		vim.ui.input({}, function(text)
			if text == nil then
				return
			end
			text = vim.trim(text)
			if string.len(text) == 0 then
				return
			end

			local node = M.new_Tree(-1, root[1].level + 1, text)
			node.open = true
			table.insert(root[1].c, node)

			root[1].nc = vim.tbl_count(root[1].c)
		end)
	end

	-- get reference to correct root of tree
	local ptree = root[1].c[1]

	-- focus root if not state is found
	if app.active == nil then
		app.active = ptree
	end
	return ptree
end

function M.save_to_file(app)
	-- convert tree to lines and save
	local lines = M.tree_to_lines(app.tree, 0)
	a.nvim_set_current_buf(app.file_buf)
	a.nvim_buf_set_lines(app.file_buf, 0, -1, false, lines)
	a.nvim_exec2('set buftype=""', {})
	a.nvim_exec2("silent write " .. app.filename, {})

	-- make sure we reset current buf and win
	a.nvim_set_current_buf(app.buf)
	a.nvim_set_current_win(app.win)
end

function M.reload(app)
	-- read hmm file buffer
	local lines = a.nvim_buf_get_lines(app.file_buf, 0, -1, false)

	-- create tree
	app.tree = M.lines_to_tree(lines, app)

	-- make sure we reset current buf and win
	a.nvim_set_current_win(app.win)
	a.nvim_set_current_buf(app.buf)
end

function M.undo(app)
	-- use neovim undo directly
	a.nvim_set_current_buf(app.file_buf)
	a.nvim_exec2("silent undo", {})
	a.nvim_exec2("silent write " .. app.filename, {})
	M.reload(app)
end

function M.redo(app)
	-- use neovim redo directly
	a.nvim_set_current_buf(app.file_buf)
	a.nvim_exec2("silent redo", {})
	a.nvim_exec2("silent write " .. app.filename, {})
	M.reload(app)
end

return M
