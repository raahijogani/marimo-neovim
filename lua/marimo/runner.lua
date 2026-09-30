local parser = require("marimo.parser")
local util = require("marimo.util")

local M = {}

---@class MarimoConfig
---@field marimo_bin string
---@field browser_open boolean
---@field server_host string
---@field server_port integer
---@field keymaps boolean
---@field preview_mode "split"|"browser"
---@field preview_command "edit"|"run"
---@field auto_start_preview boolean

local cfg = {
  marimo_bin = "marimo",
  browser_open = true,
  server_host = "127.0.0.1",
  server_port = 2718,
  keymaps = true,
  preview_mode = "browser",
  preview_command = "edit",
  auto_start_preview = false,
}

local state = {
  preview_job = nil,
  preview_buf = nil,
  preview_win = nil,
  preview_url = nil,
}

function M.get_config()
  return cfg
end

function M.setup_config(user)
  cfg = vim.tbl_deep_extend("force", cfg, user or {})
end

local function executable_or_warn()
  if vim.fn.executable(cfg.marimo_bin) == 1 then
    return true
  end
  util.notify("marimo executable not found: " .. cfg.marimo_bin, vim.log.levels.ERROR)
  return false
end

local function marimo_args(parts)
  local args = { cfg.marimo_bin }
  vim.list_extend(args, parts)
  return args
end

local opened_urls = {}

local function open_browser(url)
  if not cfg.browser_open or not url or url == "" or opened_urls[url] then
    return
  end
  opened_urls[url] = true

  if vim.ui and vim.ui.open then
    vim.ui.open(url)
    return
  end

  local opener = vim.fn.has("mac") == 1 and "open" or "xdg-open"
  if vim.fn.executable(opener) == 1 then
    vim.fn.jobstart({ opener, url }, { detach = true })
  else
    util.notify("Open browser manually: " .. url, vim.log.levels.WARN)
  end
end

local function maybe_capture_url(data)
  if not data then
    return
  end

  for _, line in ipairs(data) do
    local url = line:match("https?://[%w%p]+")
    if url then
      state.preview_url = url
      open_browser(url)
      return
    end
  end
end

local function current_file()
  return vim.fn.expand("%:p")
end

function M.run_notebook(file)
  file = file or current_file()
  if file == "" then
    util.notify("No file to run", vim.log.levels.WARN)
    return
  end

  if not executable_or_warn() then
    return
  end

  vim.cmd.write()

  local args = marimo_args({
    "run",
    file,
    "--host",
    cfg.server_host,
    "--port",
    tostring(cfg.server_port),
    "--watch",
  })

  local job = vim.fn.jobstart(args, {
    detach = true,
    on_stderr = function(_, data)
      if data and data[1] and data[1] ~= "" then
        util.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
  })

  if job <= 0 then
    util.notify("Failed to start marimo run", vim.log.levels.ERROR)
    return
  end

  util.notify("Started marimo notebook: " .. file)
end

local function write_temp_cell(cell_lines)
  local tmp = vim.fn.tempname() .. "_marimo_cell.py"
  local wrapped = {
    "import marimo",
    "app = marimo.App()",
    "",
    "@app.cell",
    "def __():",
  }

  for _, line in ipairs(cell_lines) do
    if util.trim(line) == "" then
      table.insert(wrapped, "")
    else
      table.insert(wrapped, "    " .. line)
    end
  end

  table.insert(wrapped, "")
  table.insert(wrapped, "if __name__ == \"__main__\":")
  table.insert(wrapped, "    app.run()")

  vim.fn.writefile(wrapped, tmp)
  return tmp
end

function M.run_cell(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.cmd.write()

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local cells = parser.cells_for_buf(buf)
  local cell = parser.cell_at_line(cells, lnum)

  if not cell then
    util.notify("No cell under cursor", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, cell.body_start - 1, cell.end_line, false)
  local cleaned = {}
  for _, l in ipairs(lines) do
    table.insert(cleaned, l:gsub("^    ", ""))
  end

  if not executable_or_warn() then
    return
  end

  local tmp = write_temp_cell(cleaned)
  local args = marimo_args({ cfg.preview_command, tmp, "--host", cfg.server_host, "--port", tostring(cfg.server_port) })
  local job = vim.fn.jobstart(args, { detach = true })
  if job <= 0 then
    util.notify("Failed to run cell " .. cell.index, vim.log.levels.ERROR)
    return
  end
  open_browser(string.format("http://%s:%d", cfg.server_host, cfg.server_port))
  util.notify("Running cell " .. cell.index)
end

function M.start_preview(file)
  file = file or current_file()
  if file == "" then
    util.notify("No file to preview", vim.log.levels.WARN)
    return
  end

  if not executable_or_warn() then
    return
  end

  vim.cmd.write()

  if state.preview_job and vim.fn.jobwait({ state.preview_job }, 0)[1] == -1 then
    open_browser(state.preview_url or string.format("http://%s:%d", cfg.server_host, cfg.server_port))
    util.notify("Preview already running at " .. (state.preview_url or ""))
    return
  end

  local url = string.format("http://%s:%d", cfg.server_host, cfg.server_port)
  state.preview_url = url

  local args = marimo_args({ cfg.preview_command, file, "--host", cfg.server_host, "--port", tostring(cfg.server_port), "--watch" })

  state.preview_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.preview_buf].bufhidden = "wipe"
  vim.bo[state.preview_buf].filetype = "log"

  state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.5),
    height = math.floor(vim.o.lines * 0.35),
    row = vim.o.lines - math.floor(vim.o.lines * 0.35) - 3,
    col = vim.o.columns - math.floor(vim.o.columns * 0.5) - 2,
    border = "rounded",
    style = "minimal",
    title = "marimo preview server",
  })

  state.preview_job = vim.fn.jobstart(args, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      maybe_capture_url(data)
      if data and #data > 0 and vim.api.nvim_buf_is_valid(state.preview_buf) then
        vim.api.nvim_buf_set_lines(state.preview_buf, -1, -1, false, data)
      end
    end,
    on_stderr = function(_, data)
      maybe_capture_url(data)
      if data and #data > 0 and vim.api.nvim_buf_is_valid(state.preview_buf) then
        vim.api.nvim_buf_set_lines(state.preview_buf, -1, -1, false, data)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        util.notify("marimo preview exited with code " .. code .. "; see preview log", vim.log.levels.ERROR)
      end
    end,
  })

  if state.preview_job <= 0 then
    state.preview_job = nil
    util.notify("Failed to start marimo preview", vim.log.levels.ERROR)
    return
  end

  open_browser(url)
  util.notify("Started preview server: " .. url)
end

function M.toggle_preview(file)
  if state.preview_job and vim.fn.jobwait({ state.preview_job }, 0)[1] == -1 then
    M.stop_preview()
  else
    M.start_preview(file)
  end
end

function M.stop_preview()
  if state.preview_job then
    pcall(vim.fn.jobstop, state.preview_job)
    state.preview_job = nil
  end

  if state.preview_win and vim.api.nvim_win_is_valid(state.preview_win) then
    vim.api.nvim_win_close(state.preview_win, true)
  end

  state.preview_win = nil
  state.preview_buf = nil
  state.preview_url = nil

  util.notify("Stopped preview")
end

function M.preview_status()
  if state.preview_job and vim.fn.jobwait({ state.preview_job }, 0)[1] == -1 then
    util.notify("Preview running at " .. (state.preview_url or "(unknown url)"))
  else
    util.notify("Preview not running")
  end
end

return M
