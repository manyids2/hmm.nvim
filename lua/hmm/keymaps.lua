local t = require("hmm.htree")

local M = {}

function M.toggle(app)
	app.active.open = not app.active.open
	t.render(app)
end

function M.left(app)
	local active = app.active
	if active.p == nil then
		return
	end
	app.active = active.p
	t.focus_active(app)
end

function M.right(app)
	local active = app.active
	if active.nc == 0 then
		return
	end
	if not active.open then
		active.open = true
		t.render(app)
	else
		app.active = active.c[math.ceil(active.nc / 2)]
		t.focus_active(app)
	end
end

function M.up(app)
	local active = app.active
	if active.p == nil then
		return
	end
	if active.si == 1 then
		return
	end
	app.active = active.p.c[math.max(1, active.si - 1)]
	t.focus_active(app)
end

function M.down(app)
	local active = app.active
	if active.p == nil then
		return
	end
	if active.si == active.ns then
		return
	end
	app.active = active.p.c[math.min(active.ns, active.si + 1)]
	t.focus_active(app)
end

function M.global_keymaps(app)
	local map = vim.keymap.set

	-- focus active
	map("n", "f", function()
		t.focus_active(app)
	end, { desc = "Focus" })

	-- save to source
	map("n", "s", function()
		vim.notify("Saved " .. app.filename)
	end, { buffer = app.buf, desc = "Save" })

	-- toggle node
	map("n", "<space>", function()
		M.toggle(app)
	end, { buffer = app.buf, desc = "Toggle" })

	-- navigation
	map("n", "j", function()
		M.down(app)
	end, { buffer = app.buf, desc = "Down" })

	map("n", "k", function()
		M.up(app)
	end, { buffer = app.buf, desc = "Up" })

	map("n", "h", function()
		M.left(app)
	end, { buffer = app.buf, desc = "Left" })

	map("n", "l", function()
		M.right(app)
	end, { buffer = app.buf, desc = "Right" })

	map("n", "t", function()
		vim.cmd([[:messages clear]])
		t.print_tree(app.active)
		vim.cmd([[:messages]])
	end, { buffer = app.buf, desc = "Print tree" })

	map("n", "~", function()
		vim.cmd([[:messages]])
	end, { buffer = app.buf, desc = "Messages" })
end

return M
