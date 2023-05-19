local a = vim.api
local t = require("hmm.htree")

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
	active = { space = a.nvim_create_namespace("active"), color = "IncSearch" },
	spacer = { space = a.nvim_create_namespace("spacer"), color = "Float" },
}

function M.clear_win_buf(buf, size, offset)
	-- clear active, spacers
	a.nvim_buf_clear_namespace(buf, M.highlights.active.space, 0, -1)
	a.nvim_buf_clear_namespace(buf, M.highlights.spacer.space, 0, -1)
	local replacement = { string.rep(" ", size.w) }

	-- add offset
	for i = 0, offset, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end

	-- replace existing
	replacement = { string.rep(" ", size.w) }
	for i = offset, size.h + offset, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end

	-- delete remaining
	local old_h = a.nvim_buf_line_count(buf)
	a.nvim_buf_set_lines(buf, size.h + offset, old_h + 1 + offset, false, {})
end

function M.focus_active(app)
	local active = app.active
	a.nvim_set_current_buf(app.buf)
	a.nvim_set_current_win(app.win)
	a.nvim_win_set_cursor(app.win, { active.y + active.o + 1 + app.offset, active.x })
	a.nvim_buf_clear_namespace(app.buf, M.highlights.active.space, 0, -1)
	M.draw_node(app.active)
	a.nvim_buf_add_highlight(
		app.buf,
		M.highlights.active.space,
		M.highlights.active.color,
		active.y + active.o + app.offset,
		active.x,
		active.x + active.w
	)
end

function M.draw_node(tree)
	a.nvim_buf_set_text(
		tree.app.buf,
		tree.y + tree.o + tree.app.offset,
		tree.x,
		tree.y + tree.o + tree.app.offset,
		tree.x + tree.w,
		{ " " .. tree.text .. " " }
	)
end

function M.draw_virt(buf, start_row, start_col, end_col, virt_text, highlight)
	local opts = {
		end_col = end_col,
		virt_text_win_col = start_col,
		virt_text_pos = "overlay",
		virt_text = { { virt_text, highlight.color } },
	}
	a.nvim_buf_set_extmark(buf, M.highlights.spacer.space, start_row, start_col, opts)
end

function M.render_tree(tree)
	M.draw_node(tree)
	if not tree.open then
		return
	end

	if vim.tbl_count(tree.c) > 0 then
		-- M.draw_spacer(tree)
		for _, child in ipairs(tree.c) do
			M.render_tree(child)
		end
	end
end

function M.render(app)
	-- recompute layout
	t.set_props(app.tree, 1, nil, app)
	t.set_y(app.tree, app.config)

	-- reset buffer
	local size = { h = app.tree.th, w = app.tree.tw }
	M.clear_win_buf(app.buf, size, app.offset)
	M.render_tree(app.tree)
	M.focus_active(app)
end

return M
