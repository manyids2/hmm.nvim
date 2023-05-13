local M = {}

function M.new_Tree(w, h, y, c, text)
	return {
		-- our custom metada
		text = text,
		-- predefined properties
		w = w, -- width
		h = h, -- height
		y = y, -- initial height
		c = c, -- children
		cs = vim.tbl_count(c), -- count of children
		-- attributes and explanations
		x = 0,
		prelim = 0,
		mod = 0,
		shift = 0,
		change = 0,
		tl = nil, -- left thread
		tr = nil, -- right thread
		el = nil, -- left extreme node
		er = nil, -- right extreme node
		msel = 0, -- sum of left modifiers
		mser = 0, -- sum of right modifiers
	}
end

function M.layout(t)
	M.first_walk(t)
	M.second_walk(t, 0)
end

function M.first_walk(t)
	t.cs = vim.tbl_count(t.c)
	if t.cs == 0 then
		M.set_extremes(t)
		return
	end

	-- walk the first child
	M.first_walk(t.c[1])

	-- Create siblings in contour minimal vertical coordinate and index list.
	local ih = M.update_IYL(M.bottom(t.c[1].el), 1, nil)

	-- walk siblings
	for i = 2, t.cs, 1 do
		M.first_walk(t.c[i])

		-- Store lowest vertical coordinate while extreme nodes still point in current subtree
		local minY = M.bottom(t.c[i].er)
		-- M.separate(t, i, ih)
		ih = M.update_IYL(minY, i, ih)
	end

	M.position_root(t)
	M.set_extremes(t)
end

function M.separate(t, i, ih)
	-- Right contour node of left siblings and its sum of modfiers.
	local sr = t.c[i - 1]
	local mssr = sr.mod

	-- Left contour node of current subtree and its sum of modfiers.
	local cl = t.c[i]
	local mscl = cl.mod
	while sr ~= nil and cl ~= nil do
		if M.bottom(sr) > ih.lowY then
			ih = ih.nxt
		end

		-- How far to the left of the right side of sr is the left side of cl?
		local dist = (mssr + sr.prelim + sr.w) - (mscl + cl.prelim)
		if dist > 0 then
			mscl = mscl + dist
			M.move_subtree(t, i, ih.index, dist)
		end

		-- Advance highest node(s) and sum(s) of modifiers
		local sy = M.bottom(sr)
		local cy = M.bottom(cl)
		if sy <= cy then
			sr = M.next_right_contour(sr)
			if sr ~= nil then
				mssr = mssr + sr.mod
			end
		end
		if sy >= cy then
			cl = M.next_left_contour(cl)
			if cl ~= nil then
				mscl = mscl + cl.mod
			end
		end
	end

	-- Set threads and update extreme nodes.
	-- In the first case, the current subtree must be taller than the left siblings.
	if sr == nil and cl ~= nil then
		M.set_left_thread(t, i, cl, mscl)
	-- In this case, the left siblings must be taller than the current subtree.
	elseif sr ~= nil and cl == nil then
		M.set_right_thread(t, i, sr, mssr)
	end
end

function M.set_extremes(t)
	if t.cs == 0 then
		t.el = t
		t.er = t
		t.msel = 0
		t.mser = 0
	else
		-- first child
		t.el = t.c[1].el
		t.msel = t.c[1].msel
		-- last child
		t.er = t.c[t.cs].er
		t.mser = t.c[t.cs].mser
	end
end

function M.move_subtree(t, i, si, dist)
	t.c[i].mod = t.c[i].mod + dist
	t.c[i].msel = t.c[i].msel + dist
	t.c[i].mser = t.c[i].mser + dist
	M.distribute_extra(t, i, si, dist)
end

function M.next_left_contour(t)
	if t.cs == 0 then
		return t.tl
	else
		return t.c[0]
	end
end

function M.next_right_contour(t)
	if t.cs == 0 then
		return t.tr
	else
		return t.c[t.cs - 1]
	end
end

function M.bottom(t)
	return t.y + t.h
end

function M.set_left_thread(t, i, cl, modsumcl)
	local li = t.c[0].el
	li.tl = cl
	-- Change mod so that the sum of modifier after following thread is correct
	local diff = (modsumcl - cl.mod) - t.c[0].msel
	li.mod = li.mod + diff
	-- Change preliminary x coordinate so that the node does not move
	li.prelim = li.prelim - diff
	-- Update extreme node and its sum of modifiers
	t.c[0].el = t.c[i].el
	t.c[0].msel = t.c[i].msel
end

function M.set_right_thread(t, i, sr, modsumsr)
	local ri = t.c[i].er
	ri.tr = sr
	local diff = (modsumsr - sr.mod) - t.c[i].mser
	ri.mod = ri.mod + diff
	ri.prelim = ri.prelim + diff
	t.c[i].er = t.c[i - 1].er
	t.c[i].mser = t.c[i - 1].mser
end

function M.position_root(t)
	-- Position root between children, taking into account their mod
	local prelim = t.c[1].prelim + t.c[t.cs].prelim
	local mod = t.c[1].mod + t.c[t.cs].mod
	t.prelim = (prelim + mod + t.c[t.cs].w) / 2 - t.w / 2
end

function M.second_walk(t, modsum)
	-- Set absolute (non-relative) horizontal coordinate
	modsum = modsum + t.mod
	t.x = t.prelim + modsum
	M.add_child_spacing(t)
	for i = 2, t.cs, 1 do
		M.second_walk(t.c[i], modsum)
	end
end

function M.distribute_extra(t, i, si, dist)
	-- Are there intermediate children?
	if si ~= i - 1 then
		local nr = i - si
		t.c[si + 1].shift = t.c[si + 1].shift + dist / nr
		t.c[i].shift = t.c[i].shift - dist / nr
		t.c[i].change = t.c[i].change - dist - dist / nr
	end
end

function M.add_child_spacing(t)
	-- Process change and shift to add intermediate spacing to mod
	local d = 0
	local modsumdelta = 0
	for i = 1, t.cs, 1 do
		d = d + t.c[i].shift
		modsumdelta = modsumdelta + d + t.c[i].change
		t.c[i].mod = t.c[i].mod + modsumdelta
	end
end

function M.new_IYL(lowY, index, nxt)
	-- A linked list of the indexes of left siblings and their lowest vertical coordinate
	return { lowY = lowY, index = index, nxt = nxt }
end

function M.update_IYL(minY, i, ih)
  -- do not run unbounded while loop
	local count = 0

  -- Remove siblings that are hidden by the new subtree
	while ih ~= nil and minY >= ih.lowY and count <= 1000 do
		count = count + 1
		ih = ih.nxt
	end

	if count == 1000 then
		P("exceeded max retries")
	end

	-- Prepend the new subtree
	return M.new_IYL(minY, i, ih)
end

return M
