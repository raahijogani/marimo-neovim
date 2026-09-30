local M = {}

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "marimo.nvim" })
end

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.get_visual_selection_lines()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" then
    return nil
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local s = math.min(start_pos[2], end_pos[2])
  local e = math.max(start_pos[2], end_pos[2])
  return s, e
end

function M.open_output_window(lines, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = opts.filetype or "text"

  local width = math.floor(vim.o.columns * (opts.width_ratio or 0.65))
  local height = math.floor(vim.o.lines * (opts.height_ratio or 0.35))
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = opts.title or "marimo output",
    title_pos = "center",
  })
end

function M.ensure_parent_dir(path)
  local dir = vim.fn.fnamemodify(path, ":h")
  if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

return M
