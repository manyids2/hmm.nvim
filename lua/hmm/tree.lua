local M = {}

function M.lines_to_tree(lines)
	local tabparent = { { children = {} } }
	for _, line in ipairs(lines) do
		local tabs = vim.tbl_count(vim.split(line, "\t", {}))
		local node = { text = vim.trim(line), children = {} }
		if tabparent[tabs] ~= nil then
			table.insert(tabparent[tabs].children, node)
		end
		tabparent[tabs + 1] = node
	end
	return tabparent[1].children[1]
end

function M.tree_to_lines(tree, level)
	if level == nil then
		level = 0
	end
	local lines = { string.rep("\t", level) .. tree.text }
	if vim.tbl_count(tree.children) > 0 then
		for _, child in ipairs(tree.children) do
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

return M
