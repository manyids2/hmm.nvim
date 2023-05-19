local M = {}

function M.set_props(tree, si, parent, app)
	for index, child in ipairs(tree.c) do
		M.set_props(child, index, tree, app)
	end
end

function M.set_y(tree, config)
	for _, child in ipairs(tree.c) do
		M.set_y(child, config)
	end
end

return M
