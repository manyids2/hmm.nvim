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
	local inside = (x1 >= 0) and (x2 < aw) and (y1 > 0) and (y2 < ah - 1)

	-- set the text
	if inside then
		local y = tree.y + tree.toy + ofy
		if not tree.open then
			M.draw_virt(buf, y, x1, M.symbols.hc)
		else
			M.draw_virt(buf, y, x1, string.rep(M.symbols.bh, config.margin - 5))

			for _, child in ipairs(tree.c) do
				local yc = child.y + child.toy + ofy
				M.draw_virt(buf, yc, x2 - 4, string.rep(M.symbols.bh, 2))
			end
			if nc > 1 then
				-- top and bottom
				M.draw_virt(buf, y1, x2 - 5, M.symbols.bt)
				M.draw_virt(buf, y2, x2 - 5, M.symbols.bb)
				-- vertical
				for i = y1 + 1, y2 - 1 do
					M.draw_virt(buf, i, x2 - 5, M.symbols.bv)
				end
			else
				M.draw_virt(buf, y1, x2 - 5, M.symbols.bh)
			end
		end
	end
end

return M
