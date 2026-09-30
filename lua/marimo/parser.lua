local M = {}

---@class MarimoCell
---@field index integer
---@field decorator_line integer
---@field def_line integer
---@field body_start integer
---@field end_line integer

local function is_cell_decorator(line)
  return line:match("^%s*@app%.cell") ~= nil
end

local function is_cell_def(line)
  -- marimo commonly uses def __(...):, but keep this permissive.
  return line:match("^%s*def%s+[_%w]+%s*%(") ~= nil
end

---Parse marimo cells from raw buffer lines.
---@param lines string[]
---@return MarimoCell[]
function M.parse_cells(lines)
  local decorator_lines = {}
  for i, line in ipairs(lines) do
    if is_cell_decorator(line) then
      table.insert(decorator_lines, i)
    end
  end

  local cells = {}

  for idx, decorator_line in ipairs(decorator_lines) do
    local def_line = decorator_line + 1
    while def_line <= #lines and not is_cell_def(lines[def_line] or "") do
      def_line = def_line + 1
    end

    if def_line > #lines then
      break
    end

    local next_decorator = decorator_lines[idx + 1]
    local end_line

    if next_decorator then
      end_line = next_decorator - 1
    else
      end_line = #lines
      for j = def_line + 1, #lines do
        if (lines[j] or ""):match("^%s*if%s+__name__%s*==%s*['\"]__main__['\"]%s*:") then
          end_line = j - 1
          break
        end
      end
    end

    table.insert(cells, {
      index = idx,
      decorator_line = decorator_line,
      def_line = def_line,
      body_start = math.min(def_line + 1, end_line),
      end_line = math.max(end_line, def_line),
    })
  end

  return cells
end

---@param buf integer
---@return MarimoCell[]
function M.cells_for_buf(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return M.parse_cells(lines)
end

---@param cells MarimoCell[]
---@param lnum integer 1-indexed line
---@return MarimoCell|nil
function M.cell_at_line(cells, lnum)
  for _, cell in ipairs(cells) do
    if lnum >= cell.decorator_line and lnum <= cell.end_line then
      return cell
    end
  end
  return nil
end

---@param buf integer
---@return boolean
function M.is_marimo_buffer(buf)
  if vim.bo[buf].filetype ~= "python" then
    return false
  end

  local max_scan = math.min(vim.api.nvim_buf_line_count(buf), 200)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, max_scan, false)

  for _, line in ipairs(lines) do
    if line:match("marimo%.App%s*%(") or line:match("^%s*@app%.cell") then
      return true
    end
  end

  return false
end

return M
