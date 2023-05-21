local a = vim.api
local io = require("hmm.io")
local sp = require("hmm.spacers")

local M = {}

function M.focus_active(app)
  local buf = app.buf
  local win = app.win
  local active = app.active
  local hi = io.highlights.active

  local ofx = app.offset.x
  local ofy = app.offset.y
  local y = active.y + active.toy + ofy
  local x1 = active.x + 1 + ofx
  local x2 = active.x + 1 + active.w + ofx
  local aw = app.size.w
  local ah = app.size.h

  a.nvim_win_set_cursor(win, { 1, 0 })
  io.focus(buf, win, hi, y, x1, x2, ah, aw)
  io.hide_cursor()
end

function M.draw_node(buf, tree)
  local ofx = tree.app.offset.x
  local ofy = tree.app.offset.y
  local y = tree.y + tree.toy + ofy
  local x1 = tree.x + 1 + ofx
  local x2 = tree.x + 1 + tree.w + ofx

  -- check bounds
  local aw = tree.app.size.w
  local ah = tree.app.size.h
  local inside = (x1 >= 0) and (x2 < aw) and (y >= 0) and (y < ah - 1)

  -- set the text
  if inside then
    a.nvim_buf_set_text(buf, y, x1, y, x2, { tree.text })
  end
end

function M.position_root(app)
  app.offset.x = 10
  app.offset.y = 10
end

function M.set_si(tree)
  for index, child in ipairs(tree.c) do
    child.si = index
    M.set_si(child)
  end
end

function M.set_cw(tree)
  local cw = 0
  for _, child in ipairs(tree.c) do
    cw = math.max(cw, child.w)
  end
  tree.cw = cw
  for _, child in ipairs(tree.c) do
    M.set_cw(child)
  end
end

function M.set_x(tree, config)
  for _, child in ipairs(tree.c) do
    local pcw = tree.w
    if config.align_levels and (tree.p ~= nil) then
      pcw = tree.p.cw
    end
    child.x = tree.x + pcw + config.margin
    M.set_x(child, config)
  end
end

function M.set_ch(tree, config)
  for _, child in ipairs(tree.c) do
    M.set_ch(child, config)
  end
  if not tree.open then
    tree.ch = tree.h + config.line_spacing
    return
  end
  local ch = 0
  if vim.tbl_count(tree.c) == 0 then
    tree.ch = tree.h + config.line_spacing
  else
    for _, child in ipairs(tree.c) do
      ch = ch + child.ch
    end
    tree.ch = ch
  end
end

function M.set_y(tree, config)
  local y = tree.y
  for _, child in ipairs(tree.c) do
    child.y = y
    M.set_y(child, config)
    y = y + child.ch
  end
end

function M.set_o(tree, config)
  tree.toy = math.floor(tree.ch / 2)
  for _, child in ipairs(tree.c) do
    M.set_o(child, config)
  end
end

function M.set_bounds(tree, config)
  tree.tx = tree.x
  tree.ty = tree.y
  tree.th = tree.ch
  if not tree.open then
    tree.tw = tree.w
    return
  end
  local tw = 0
  for _, child in ipairs(tree.c) do
    M.set_bounds(child, config)
    tw = math.max(tw, child.tw)
  end
  tree.tw = tree.w + config.margin + tw
end

function M.layout_htree(tree, config)
  M.set_si(tree)
  M.set_cw(tree)
  M.set_x(tree, config)
  M.set_ch(tree, config)
  M.set_y(tree, config)
  M.set_o(tree, config)
  M.set_bounds(tree, config)
end

function M.set_offset_to_active(app)
  local active = app.active
  local y = active.y + active.toy
  local x = active.x + 1
  app.offset.x = app.center.x - x
  app.offset.y = app.center.y - y
end

function M.layout_list(tree, config)
  tree.x = (tree.level - 1) * config.list_indent
  tree.y = tree.index - 1
  for _, child in ipairs(tree.c) do
    M.layout_list(child, config)
  end
end

function M.render_tree(buf, tree, config)
  M.draw_node(buf, tree)
  sp.draw_spacer(buf, tree, config)
  if not tree.open then
    return
  end

  if vim.tbl_count(tree.c) > 0 then
    for _, child in ipairs(tree.c) do
      M.render_tree(buf, child, config)
    end
  end
end

function M.layout(app)
  if app.config.mode == "list" then
    M.layout_list(app.root, app.config)
  else
    M.layout_htree(app.root, app.config)
  end
end

function M.render(app)
  -- reset size
  local size = io.get_size_center(app.win)
  app.size = { w = size.w, h = size.h }
  app.center = { x = size.x, y = size.y }

  -- compute layout, so we get x, y of active
  M.layout(app)

  -- reset buffer
  io.clear_win_buf(app.buf, app.size)

  -- render to buffer
  M.render_tree(app.buf, app.root, app.config)

  -- set focus
  M.focus_active(app)
end

function M.destroy(app)
  a.nvim_buf_delete(app.file_buf, { force = true })
  a.nvim_buf_delete(app.buf, { force = true })
end

return M
