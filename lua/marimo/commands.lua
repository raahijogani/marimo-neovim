local notebook = require("marimo.notebook")
local runner = require("marimo.runner")
local util = require("marimo.util")
local view = require("marimo.view")

local M = {}

local function expand_arg(arg)
  if not arg or arg == "" then
    return nil
  end
  return vim.fn.expand(arg)
end

function M.setup_commands()
  vim.api.nvim_create_user_command("MarimoNew", function(opts)
    notebook.new_notebook(expand_arg(opts.args) or "notebook.py")
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("MarimoOpen", function(opts)
    notebook.open_notebook(expand_arg(opts.args), false)
  end, { nargs = 1, complete = "file" })

  vim.api.nvim_create_user_command("MarimoOpenTab", function(opts)
    notebook.open_notebook(expand_arg(opts.args), true)
  end, { nargs = 1, complete = "file" })

  vim.api.nvim_create_user_command("MarimoRun", function(opts)
    runner.run_notebook(expand_arg(opts.args))
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("MarimoRunCell", function()
    runner.run_cell()
  end, {})

  vim.api.nvim_create_user_command("MarimoPreviewStart", function(opts)
    runner.start_preview(expand_arg(opts.args))
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("MarimoPreviewStop", function()
    runner.stop_preview()
  end, {})

  vim.api.nvim_create_user_command("MarimoPreviewStatus", function()
    runner.preview_status()
  end, {})

  vim.api.nvim_create_user_command("MarimoPreviewToggle", function(opts)
    runner.toggle_preview(expand_arg(opts.args))
  end, { nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("MarimoCellNext", function()
    notebook.next_cell()
  end, {})

  vim.api.nvim_create_user_command("MarimoCellPrev", function()
    notebook.prev_cell()
  end, {})

  vim.api.nvim_create_user_command("MarimoCellAddBelow", function(opts)
    notebook.add_cell_below(0, (opts.args or ""):lower() == "md")
    view.refresh()
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("MarimoCellDelete", function()
    notebook.delete_cell()
    view.refresh()
  end, {})

  vim.api.nvim_create_user_command("MarimoCellGoto", function(opts)
    local idx = tonumber(opts.args)
    if not idx then
      util.notify("Cell index must be a number", vim.log.levels.ERROR)
      return
    end
    notebook.goto_cell(idx)
  end, { nargs = 1 })

  vim.api.nvim_create_user_command("MarimoToggleView", function()
    view.toggle()
  end, {})
end

function M.setup_keymaps()
  local map = vim.keymap.set
  local opts = { noremap = true, silent = true }

  map("n", "]c", "<cmd>MarimoCellNext<cr>", opts)
  map("n", "[c", "<cmd>MarimoCellPrev<cr>", opts)
  map("n", "<leader>ma", "<cmd>MarimoCellAddBelow<cr>", opts)
  map("n", "<leader>mm", "<cmd>MarimoCellAddBelow md<cr>", opts)
  map("n", "<leader>md", "<cmd>MarimoCellDelete<cr>", opts)
  map("n", "<leader>mr", "<cmd>MarimoRunCell<cr>", opts)
  map("n", "<leader>mR", "<cmd>MarimoRun<cr>", opts)
  map("n", "<leader>mo", "<cmd>MarimoOpen ", { noremap = true })
  map("n", "<leader>mO", "<cmd>MarimoOpenTab ", { noremap = true })
  map("n", "<leader>mp", "<cmd>MarimoPreviewStart<cr>", opts)
  map("n", "<leader>mt", "<cmd>MarimoPreviewToggle<cr>", opts)
  map("n", "<leader>mP", "<cmd>MarimoPreviewStop<cr>", opts)
  map("n", "<leader>mv", "<cmd>MarimoToggleView<cr>", opts)
  map("n", "<leader>mn", "<cmd>MarimoNew<cr>", opts)
end

return M
