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
	bc = "┼",
	bnc = "┤",
	hc = "    ",
	cr = "──────",
	cc = "──",
	m = 3,
}

M.highlights = {
	active = { space = a.nvim_create_namespace("active"), color = "IncSearch" },
	spacer = { space = a.nvim_create_namespace("spacer"), color = "Float" },
}

function M.clear_win_buf(buf, size, offset)
	-- clear active, spacers
	local w = size.w + a.nvim_strwidth(M.symbols.hc)
	a.nvim_buf_clear_namespace(buf, M.highlights.active.space, 0, -1)
	a.nvim_buf_clear_namespace(buf, M.highlights.spacer.space, 0, -1)
	local replacement = { string.rep(" ", w) }

	-- add offset
	for i = 0, offset, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end

	-- replace existing
	replacement = { string.rep(" ", w) }
	for i = offset, size.h + offset, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end

	-- delete remaining
	local old_h = a.nvim_buf_line_count(buf)
	a.nvim_buf_set_lines(buf, size.h + offset, old_h + 1 + offset, false, {})

	-- add padding to remove line col `~`
	replacement = { string.rep(" ", w) }
	for i = size.h + offset, size.h + offset + offset, 1 do
		a.nvim_buf_set_lines(buf, i, i, false, replacement)
	end
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

function M.draw_virt(buf, start_row, start_col, end_col, virt_text, highlight)
	local opts = {
		end_col = end_col,
		virt_text_win_col = start_col,
		virt_text_pos = "overlay",
		virt_text = { { virt_text, highlight.color } },
	}
	a.nvim_buf_set_extmark(buf, highlight.space, start_row, start_col, opts)
end

function M.draw_node(tree)
	local row = tree.y + tree.o + tree.app.offset
	local col = tree.x
	local nc = vim.tbl_count(tree.c)

	-- set the text
	a.nvim_buf_set_text(tree.app.buf, row, col, row, col + tree.w, { " " .. tree.text .. " " })

	if nc == 0 then
		return
	end

	-- set virt if not open and has children
	local s
	if not tree.open then
		s = M.symbols.hc
		M.draw_virt(tree.app.buf, row, col + tree.w, col + tree.w + a.nvim_strwidth(s), s, M.highlights.spacer)
	else
		s = M.symbols.cr
		M.draw_virt(tree.app.buf, row, col + tree.w, col + tree.w + a.nvim_strwidth(s), s, M.highlights.spacer)

		-- child lines
		for _, child in ipairs(tree.c) do
			s = M.symbols.cc
			M.draw_virt(
				tree.app.buf,
				child.y + child.o + tree.app.offset,
				child.x - a.nvim_strwidth(s),
				child.x,
				s,
				M.highlights.spacer
			)
		end

		if nc > 1 then
			local first = tree.c[1]
			local last = tree.c[nc]
			local cc = M.symbols.cc
			-- top
			s = M.symbols.bt

			M.draw_virt(
				tree.app.buf,
				first.y + first.o + tree.app.offset,
				first.x - a.nvim_strwidth(cc) - a.nvim_strwidth(s),
				first.x - a.nvim_strwidth(cc),
				s,
				M.highlights.spacer
			)

			-- bot
			s = M.symbols.bb
			M.draw_virt(
				tree.app.buf,
				last.y + last.o + tree.app.offset,
				last.x - a.nvim_strwidth(cc) - a.nvim_strwidth(s),
				last.x - a.nvim_strwidth(cc),
				s,
				M.highlights.spacer
			)

			-- vertical
			s = M.symbols.bv
			local ncr = a.nvim_strwidth(M.symbols.cr)
			for i = first.y + first.o + 1 + tree.app.offset, last.y + last.o - 1 + tree.app.offset do
				if i ~= row then
					M.draw_virt(
						tree.app.buf,
						i,
						col + tree.w + ncr,
						col + tree.w + ncr + a.nvim_strwidth(s),
						s,
						M.highlights.spacer
					)
				end
			end

			-- joins
			s = M.symbols.bj
			for i = 2, nc - 1 do
				local cy = tree.c[i].y + tree.c[i].o + tree.app.offset
				if cy ~= row then
					M.draw_virt(
						tree.app.buf,
						tree.c[i].y + tree.c[i].o + tree.app.offset,
						col + tree.w + ncr,
						col + tree.w + ncr + a.nvim_strwidth(s),
						s,
						M.highlights.spacer
					)
				end
			end
		end

		-- TODO: last
		if nc == 1 then
			s = M.symbols.bh
		else
			if (tree.tw / 2) - math.floor(tree.tw / 2) > 0 then
				s = M.symbols.bc
			else
				s = M.symbols.bnc
			end
		end
		local hcw = a.nvim_strwidth(M.symbols.hc) + 1
		M.draw_virt(
			tree.app.buf,
			row,
			col + tree.w + hcw,
			col + tree.w + hcw + a.nvim_strwidth(s),
			s,
			M.highlights.spacer
		)
	end
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
