local parser = require("marimo.parser")
local util = require("marimo.util")

local M = {}

local DEFAULT_TEMPLATE = {
  "import marimo",
  "",
  "__generated_with = \"0.0.0\"",
  "app = marimo.App()",
  "",
  "",
  "@app.cell",
  "def __():",
  "    return",
  "",
  "",
  "if __name__ == \"__main__\":",
  "    app.run()",
}

---@param buf integer
---@return integer
local function main_guard_line(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("^%s*if%s+__name__%s*==%s*['\"]__main__['\"]%s*:") then
      return i
    end
  end
  return #lines + 1
end

local function cell_stub()
  return {
    "@app.cell",
    "def __():",
    "    return",
    "",
  }
end

function M.new_notebook(path)
  path = path or "notebook.py"
  util.ensure_parent_dir(path)
  vim.fn.writefile(DEFAULT_TEMPLATE, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  util.notify("Created marimo notebook: " .. path)
end

function M.open_notebook(path, in_tab)
  if not path or path == "" then
    util.notify("Path required", vim.log.levels.WARN)
    return
  end

  if in_tab then
    vim.cmd.tabedit(vim.fn.fnameescape(path))
  else
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
end

---@param buf integer
---@param line integer 1-indexed
---@return integer|nil
local function cell_index_at_line(buf, line)
  local cells = parser.cells_for_buf(buf)
  local cell = parser.cell_at_line(cells, line)
  return cell and cell.index or nil
end

function M.goto_cell(index, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local cells = parser.cells_for_buf(buf)
  local cell = cells[index]
  if not cell then
    util.notify("Cell " .. index .. " not found", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_win_set_cursor(0, { cell.body_start, 4 })
end

function M.next_cell(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local idx = cell_index_at_line(buf, cursor[1])
  if not idx then
    M.goto_cell(1, buf)
    return
  end
  M.goto_cell(idx + 1, buf)
end

function M.prev_cell(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local idx = cell_index_at_line(buf, cursor[1])
  if not idx then
    M.goto_cell(1, buf)
    return
  end
  M.goto_cell(math.max(idx - 1, 1), buf)
end

---@param buf? integer
function M.add_cell_below(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local cells = parser.cells_for_buf(buf)
  local current = parser.cell_at_line(cells, line)
  local insert_line

  if current then
    insert_line = current.end_line
  else
    insert_line = main_guard_line(buf) - 1
  end

  vim.api.nvim_buf_set_lines(buf, insert_line, insert_line, false, cell_stub())
  util.notify("Added cell")
end

function M.delete_cell(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local cells = parser.cells_for_buf(buf)
  local current = parser.cell_at_line(cells, line)
  if not current then
    util.notify("No cell under cursor", vim.log.levels.WARN)
    return
  end

  local start0 = current.decorator_line - 1
  local end0 = current.end_line
  vim.api.nvim_buf_set_lines(buf, start0, end0, false, {})
  util.notify("Deleted cell " .. current.index)
end

return M
