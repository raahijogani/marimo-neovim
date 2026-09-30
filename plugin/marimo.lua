if vim.g.loaded_marimo_nvim == 1 then
  return
end
vim.g.loaded_marimo_nvim = 1

-- The plugin can be configured explicitly with require("marimo").setup(...)
-- This default setup is safe and keeps commands available out-of-the-box.
require("marimo").setup({})
