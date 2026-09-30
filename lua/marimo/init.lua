local commands = require("marimo.commands")
local parser = require("marimo.parser")
local runner = require("marimo.runner")
local view = require("marimo.view")

local M = {}

---@class MarimoNvimConfig
---@field marimo_bin? string
---@field browser_open? boolean
---@field server_host? string
---@field server_port? integer
---@field keymaps? boolean
---@field preview_mode? "split"|"browser"
---@field auto_start_preview? boolean

function M.setup(opts)
  opts = opts or {}

  runner.setup_config(opts)
  commands.setup_commands()
  view.setup()

  if runner.get_config().keymaps then
    commands.setup_keymaps()
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
      if parser.is_marimo_buffer(args.buf) then
        view.refresh(args.buf)

        if runner.get_config().auto_start_preview then
          runner.start_preview(vim.api.nvim_buf_get_name(args.buf))
        end
      end
    end,
  })
end

return M
