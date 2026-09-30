-- Symlink this file into your Neovim lazy.nvim plugin specs directory,
-- e.g. ~/.config/nvim/lua/plugins/marimo.lua

return {
  {
    -- For local development (this repository)
    dir = "/home/raahi/Projects/marimo-neovim",
    name = "marimo.nvim",
    ft = { "python" },
    config = function()
      require("marimo").setup({
        marimo_bin = "marimo",
        browser_open = true,
        server_host = "127.0.0.1",
        server_port = 2718,
        keymaps = true,
        preview_mode = "browser", -- "browser" or "split"
        preview_command = "edit", -- "edit" opens marimo session UI; "run" runs app-only mode
        auto_start_preview = false,
      })
    end,
  },

  -- If/when you publish this plugin, replace the block above with:
  -- {
  --   "your-username/marimo.nvim",
  --   ft = { "python" },
  --   config = function()
  --     require("marimo").setup({
  --       marimo_bin = "marimo",
  --     })
  --   end,
  -- },
}
