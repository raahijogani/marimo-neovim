local parser = require("marimo.parser")

local M = {}

M.ns = vim.api.nvim_create_namespace("marimo_view")

---@class MarimoViewState
---@field visible boolean
---@field marks table<integer, integer> extmark id by cell index

local state_by_buf = {}

local function get_state(buf)
  state_by_buf[buf] = state_by_buf[buf] or { visible = true, marks = {} }
  return state_by_buf[buf]
end

local function clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  local st = get_state(buf)
  st.marks = {}
end

local function conceal_line(buf, lnum0)
  -- Conceal whole line contents. Newline remains; buffer stays editable/source-safe.
  local line = vim.api.nvim_buf_get_lines(buf, lnum0, lnum0 + 1, false)[1] or ""
  vim.api.nvim_buf_set_extmark(buf, M.ns, lnum0, 0, {
    end_row = lnum0,
    end_col = #line,
    hl_group = "Conceal",
    conceal = "",
  })
end

local function enable_conceal_for_buf_windows(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win].conceallevel = math.max(vim.wo[win].conceallevel, 2)
    vim.wo[win].concealcursor = "nc"
  end
end

---@param buf integer
---@param cell MarimoCell
local function decorate_cell(buf, cell)
  local id = vim.api.nvim_buf_set_extmark(buf, M.ns, cell.decorator_line - 1, 0, {
    virt_lines = { { { string.format("[Cell %d]", cell.index), "Title" } } },
    virt_lines_above = true,
  })

  local st = get_state(buf)
  st.marks[cell.index] = id

  conceal_line(buf, cell.decorator_line - 1)
  conceal_line(buf, cell.def_line - 1)
end

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if not parser.is_marimo_buffer(buf) then
    clear(buf)
    return
  end

  local st = get_state(buf)
  if not st.visible then
    clear(buf)
    return
  end

  enable_conceal_for_buf_windows(buf)

  clear(buf)

  local cells = parser.cells_for_buf(buf)
  for _, cell in ipairs(cells) do
    decorate_cell(buf, cell)
  end
end

function M.show(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  get_state(buf).visible = true
  M.refresh(buf)
end

function M.hide(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  get_state(buf).visible = false
  clear(buf)
end

function M.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local st = get_state(buf)
  if st.visible then
    M.hide(buf)
  else
    M.show(buf)
  end
end

function M.on_insert_enter(buf)
  M.hide(buf)
end

function M.on_insert_leave(buf)
  M.show(buf)
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TextChanged", "TextChangedI" }, {
    callback = function(args)
      M.refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    callback = function(args)
      if parser.is_marimo_buffer(args.buf) then
        M.on_insert_enter(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function(args)
      if parser.is_marimo_buffer(args.buf) then
        M.on_insert_leave(args.buf)
      end
    end,
  })
end

return M
