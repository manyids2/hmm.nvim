local a = vim.api
local io = require("hmm.io")

local M = {}

function M.draw_node(buf, tree)
	local ofx = tree.app.offset.x
	local ofy = tree.app.offset.y
	local y = tree.y + ofy
	local x1 = tree.x + 1 + ofx
	local x2 = tree.x + 1 + tree.w + ofx

	-- check bounds
	local aw = tree.app.size.w
	local ah = tree.app.size.h
	local inside = (x1 >= 0) and (x2 < aw) and (y >= 0) and (y < ah)

	-- set the text
	if inside then
		a.nvim_buf_set_text(buf, y, x1, y, x2, { tree.text })
	end
end

function M.render_tree(buf, tree)
	M.draw_node(buf, tree)
	if not tree.open then
		return
	end

	if vim.tbl_count(tree.c) > 0 then
		-- M.draw_spacer(tree)
		for _, child in ipairs(tree.c) do
			M.render_tree(buf, child)
		end
	end
end

function M.render(app)
	-- reset size
	local size = io.get_size_center(app.win)
	app.size = { w = size.w, h = size.h }
	app.center = { x = size.x, y = size.y }

	-- recompute layout
	M.layout_htree(app.tree)

	-- reset buffer
	io.clear_win_buf(app.buf, app.size)
	M.render_tree(app.buf, app.tree)
	io.focus_active(app)
end

function M.layout_htree(tree)
	tree.x = tree.level * tree.app.config.max_parent_node_width
	for _, child in ipairs(tree.c) do
		M.layout_htree(child)
	end
end

return M
