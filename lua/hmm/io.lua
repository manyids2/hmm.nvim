local a = vim.api

local M = {}

M.highlights = {
	active = { space = a.nvim_create_namespace("active"), color = "IncSearch" },
	spacer = { space = a.nvim_create_namespace("spacer"), color = "Whitespace" },
	tip = { space = a.nvim_create_namespace("tip"), color = "DiagnosticUnnecessary" },
}

function M.new_Tree(index, level, text, parent, appstate)
	text = vim.trim(text)
	local state = M.get_state_from_text(text)
	return {
		-- our custom metada
		app = appstate, -- state for file
		index = index,
		level = level,
		text = state.text,
		open = state.open,
		active = state.active,
		-- base props
		p = parent, -- parent
		c = {}, -- children
		nc = 0, -- number of OPEN children
		ns = 0, -- number of siblings
		si = 1, -- ith child
		-- node props
		x = 0,
		y = 0,
		w = state.w,
		h = state.h,
		-- child props
		cx = state.w + 1,
		cy = 0,
		cw = 0,
		ch = state.h,
		-- tree props
		tx = 0,
		ty = 0,
		tox = 0,
		toy = 0,
		tw = state.w,
		th = state.h,
	}
end

function M.set_text(tree, text)
	text = vim.trim(text)
	local w = string.len(text)
	local h = 1
	tree.text = text
	tree.w = w
	tree.h = h
	tree.cx = w + 1
	tree.ch = h
	tree.tw = w
	tree.th = h
end

function M.print_tree(t)
	for key, value in pairs(t) do
		if key ~= "c" then
			print(key, value)
		end
	end
end

function M.get_state_from_text(text)
	-- defaults
	local has = false
	local open = false
	local active = false
	local w = string.len(text)
	-- basically check last 3 characters
	if string.sub(text, w - 2, w - 2) == "|" then
		has = true
		open = string.sub(text, w - 1, w - 1) == "1"
		active = string.sub(text, w, w) == "1"
		-- reset width and text
		text = string.sub(text, 1, w - 3)
		w = string.len(text)
	end
	-- NOTE: change to multiline here if needed
	return { h = 1, w = w, active = active, open = open, has = has, text = text }
end

function M.get_text_for_state(tree)
	-- 00, 10, 01, 11
	local open = tree.open and "1" or "0"
	local active = tree.app.active == tree and "1" or "0"
	return open .. active
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

function M.lines_to_tree(lines, appstate)
	-- initialize root ( will be discarded )
	local root = { M.new_Tree(0, 0, "root", nil, appstate) }

	-- one node for each line
	for index, line in ipairs(lines) do
		-- only consider non-empty lines
		if string.len(vim.trim(line)) ~= 0 then
			-- get indent level
			local level = vim.tbl_count(vim.split(line, "\t", {}))

			-- set up new node
			local node = M.new_Tree(index, level, line, root[level], appstate)

			-- mark active
			if node.active then
				appstate.active = node
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

			local node = M.new_Tree(1, root[1].level + 1, text, root[1], appstate)
			node.open = true
			table.insert(root[1].c, node)

			root[1].nc = vim.tbl_count(root[1].c)
		end)
	end

	-- get reference to correct root of tree
	local ptree = root[1].c[1]
	ptree.p = nil

	-- focus root if not appstate is found
	if appstate.active == nil then
		appstate.active = ptree
	end
	return ptree
end

function M.save_to_file(state)
	-- convert tree to lines and save
	local lines = M.tree_to_lines(state.root, 0)
	a.nvim_set_current_buf(state.fbuf)
	a.nvim_buf_set_lines(state.fbuf, 0, -1, false, lines)
	a.nvim_exec2('set buftype=""', {})
	a.nvim_exec2("silent write " .. state.filename, {})

	-- make sure we reset current buf and win
	a.nvim_set_current_buf(state.buf)
	a.nvim_set_current_win(state.win)
end

function M.reload(state)
	-- read hmm file buffer
	local lines = a.nvim_buf_get_lines(state.fbuf, 0, -1, false)

	-- create tree
	state.root = M.lines_to_tree(lines, state)

	-- make sure we reset current buf and win
	a.nvim_set_current_win(state.win)
	a.nvim_set_current_buf(state.buf)

	-- reset the size as well
	local size = M.get_size_center(state.win)
	state.size = { w = size.w, h = size.h }
	state.center = { x = size.x, y = size.y }
end

function M.undo(state)
	-- use neovim undo directly
	a.nvim_set_current_buf(state.fbuf)
	a.nvim_exec2("silent undo", {})
	a.nvim_exec2("silent write " .. state.filename, {})
	M.reload(state)
end

function M.redo(state)
	-- use neovim redo directly
	a.nvim_set_current_buf(state.fbuf)
	a.nvim_exec2("silent redo", {})
	a.nvim_exec2("silent write " .. state.filename, {})
	M.reload(state)
end

function M.hide_cursor()
	local hl = a.nvim_get_hl(0, { name = "Cursor" })
	hl.blend = 100
	vim.api.nvim_set_hl(0, "Cursor", hl)
	vim.opt.guicursor:append("a:Cursor/lCursor")
end

function M.show_cursor()
	local hl = a.nvim_get_hl(0, { name = "Cursor" })
	hl.blend = 0
	vim.api.nvim_set_hl(0, "Cursor", hl)
	vim.opt.guicursor:remove("a:Cursor/lCursor")
end

function M.get_size_center(win)
	local w = a.nvim_win_get_width(win) - 6 -- no idea why
	local h = a.nvim_win_get_height(win)
	return {
		w = w,
		h = h,
		x = math.floor(w / 2),
		y = math.floor(h / 2),
	}
end

function M.clear_win_buf(buf, size)
	-- clear active, spacers
	local hi = M.highlights
	a.nvim_buf_clear_namespace(buf, hi.active.space, 0, -1)
	a.nvim_buf_clear_namespace(buf, hi.spacer.space, 0, -1)
	local replacement = { string.rep(" ", size.w) }

	if size.h > 0 then
		-- delete current
		for _ = 1, size.h - 1 do
			a.nvim_buf_set_lines(buf, -2, -1, false, {})
		end
	end

	-- clear buffer ( i.e. win )
	for i = 0, size.h - 2 do
		a.nvim_buf_set_lines(buf, i, i, true, replacement)
	end
	a.nvim_buf_set_lines(buf, -2, -1, true, {})
end

function M.focus(buf, win, hi, y, x1, x2, ah, aw)
	local inside = (x1 >= 0) and (x2 < aw) and (y > 0) and (y < ah - 1)
	if not inside then
		return
	end
	a.nvim_win_set_cursor(win, { y + 1, x1 })
	a.nvim_buf_clear_namespace(buf, hi.space, 0, -1)
	a.nvim_buf_add_highlight(buf, hi.space, hi.color, y, x1, x2)
end

function M.pad_lines(lines, width, height)
	local maxw = 0
	for _, line in ipairs(lines) do
		maxw = math.max(maxw, string.len(line))
	end
	local plines = {}
	for _ = 1, math.floor((height - vim.tbl_count(lines)) / 2) do
		table.insert(plines, "")
	end
	local padding = string.rep(" ", math.floor((width - maxw) / 2))
	for _, line in ipairs(lines) do
		table.insert(plines, padding .. line)
	end
	return plines
end

function M.pad_left_top(lines, left, top)
	local plines = {}
	for _ = 1, top do
		table.insert(plines, "")
	end
	for _, line in ipairs(lines) do
		table.insert(plines, string.rep(" ", left) .. line)
	end
	return plines
end

function M.show_help(win, buf)
	local hi = M.highlights.tip
	local text = "   press ? for help, z for config "
	local width = a.nvim_win_get_width(win)
	local row = 0
	local col = width - string.len(text)
	local opts = {
		virt_text_pos = "overlay",
		virt_text = { { text, hi.color } },
	}

	a.nvim_buf_set_extmark(buf, hi.space, row, col, opts)
end

function M.map_close_buffer(win, buf)
	local map = vim.keymap.set
	-- focus active
	map("n", "<esc>", function()
		a.nvim_win_close(win, false)
		a.nvim_buf_delete(buf, { force = false })
	end, { desc = "Close", buffer = buf })

	-- focus active
	map("n", "q", function()
		a.nvim_win_close(win, false)
		a.nvim_buf_delete(buf, { force = false })
	end, { desc = "Close", buffer = buf })
end

return M
