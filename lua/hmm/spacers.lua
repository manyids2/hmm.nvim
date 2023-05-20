local a = vim.api
local io = require("hmm.io")
local hi = io.highlights.spacer

local M = {}

M.symbols = {
	bs = " ",
	bh = "─",
	bv = "│",
	bt = "╭",
	bb = "╰",
	bc = "├", -- to child
	bx = "┼", -- root and child
	bp = "┤", -- to root
	hc = "  ", -- has children
	m = 3,
}

function M.draw_virt(buf, start_row, start_col, virt_text)
	local opts = {
		virt_text_pos = "overlay",
		virt_text = { { virt_text, hi.color } },
		strict = false,
	}
	a.nvim_buf_set_extmark(buf, hi.space, start_row, start_col, opts)
end

function M.draw_spacer(buf, tree, config)
	-- TODO: There is a more intelligent way to do this
	-- treat the spacer as a rectangle and draw only visible
	local nc = vim.tbl_count(tree.c)
	if nc == 0 then
		return
	end

	-- compute position
	local ofx = tree.app.offset.x
	local ofy = tree.app.offset.y
	local topc = tree.c[1]
	local botc = tree.c[nc]
	local y1 = topc.y + topc.toy + ofy
	local y2 = botc.y + botc.toy + ofy
	local x1 = tree.x + tree.w + ofx + 2
	local x2 = x1 + config.margin

	-- check bounds
	local aw = tree.app.size.w
	local ah = tree.app.size.h

	-- set the text
	local inside
	local y = tree.y + tree.toy + ofy
	if not tree.open then
		-- has children
		inside = (x1 >= 0) and (x1 < aw) and (y > 0) and (y < ah - 1)
		if inside then
			M.draw_virt(buf, y, x1, M.symbols.hc)
		end
	else
		-- spacer from parent to children
		inside = (x1 >= 0) and (x1 + config.margin - 5 < aw) and (y > 0) and (y < ah - 1)
		if inside then
			M.draw_virt(buf, y, x1, string.rep(M.symbols.bh, config.margin - 5))
		end

		-- vertical line
		for _, child in ipairs(tree.c) do
			local yc = child.y + child.toy + ofy
			inside = (x2 - 4 >= 0) and (x2 - 4 < aw) and (yc > 0) and (yc < ah - 1)
			if inside then
				M.draw_virt(buf, yc, x2 - 4, string.rep(M.symbols.bh, 2))
			end
		end
		if nc > 1 then
			-- top and bottom
			inside = (x2 - 5 >= 0) and (x2 - 5 < aw) and (y1 > 0) and (y1 < ah - 1)
			if inside then
				M.draw_virt(buf, y1, x2 - 5, M.symbols.bt)
			end

			inside = (x2 - 5 >= 0) and (x2 - 5 < aw) and (y2 > 0) and (y2 < ah - 1)
			if inside then
				M.draw_virt(buf, y2, x2 - 5, M.symbols.bb)
			end
			-- vertical
			for i = y1 + 1, y2 - 1 do
				inside = (x2 - 5 >= 0) and (x2 - 5 < aw) and (i > 0) and (i < ah - 1)
				if inside then
					M.draw_virt(buf, i, x2 - 5, M.symbols.bv)
				end
			end
		else
			inside = (x2 - 5 >= 0) and (x2 - 5 < aw) and (y1 > 0) and (y1 < ah - 1)
			if inside then
				M.draw_virt(buf, y1, x2 - 5, M.symbols.bh)
			end
		end
	end
end

return M
