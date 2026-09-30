# marimo.nvim

Neovim plugin that treats a `marimo` Python notebook file as an editable, cell-based document, while using the marimo browser UI as the live runner/preview.

## What this plugin does

- Detects marimo-style Python notebooks (`@app.cell` + `marimo.App()`)
- Adds **cell labels** in-buffer (`[Cell 1]`, `[Cell 2]`, ...)
- Hides marimo boilerplate (`@app.cell` and `def __():`) in normal mode
- Reveals full source in insert mode (for direct editing)
- Provides commands and keymaps to:
  - jump between cells
  - add/delete cells
  - run current cell
  - run whole notebook
  - start/stop preview server
  - create new notebooks
  - open another notebook in current buffer or new tab

---

## Requirements

- Neovim `>= 0.9`
- Python + `marimo` installed and available in PATH (or configure `marimo_bin`)

Install marimo:

```bash
pip install marimo
```

---

## Installation

### Local lazy.nvim spec file (for symlinking)

This repository includes:

- `lazy/marimo.lua`

You can symlink it into your Neovim plugin specs directory:

```bash
ln -s /home/raahi/Projects/marimo-neovim/lazy/marimo.lua ~/.config/nvim/lua/plugins/marimo.lua
```

Then restart Neovim and run `:Lazy sync`.


### lazy.nvim

```lua
{
  "<your-username>/marimo.nvim",
  config = function()
    require("marimo").setup({
      marimo_bin = "marimo",
      browser_open = true,
      server_host = "127.0.0.1",
      server_port = 2718,
      keymaps = true,
      preview_mode = "browser", -- "browser" | "split"
      preview_command = "edit", -- "edit" opens marimo session UI; "run" runs app-only mode
      auto_start_preview = false,
    })
  end,
}
```

### packer.nvim

```lua
use {
  "<your-username>/marimo.nvim",
  config = function()
    require("marimo").setup({})
  end,
}
```

---

## Commands

- `:MarimoNew [path]` — create a new marimo notebook
- `:MarimoOpen <path>` — open notebook in current buffer
- `:MarimoOpenTab <path>` — open notebook in new tab
- `:MarimoRun [path]` — run full notebook via marimo
- `:MarimoRunCell` — run cell under cursor
- `:MarimoPreviewStart [path]` — start notebook preview server
- `:MarimoPreviewStop` — stop preview server
- `:MarimoPreviewStatus` — show preview status
- `:MarimoPreviewToggle [path]` — start/stop preview; starting opens browser
- `:MarimoCellNext` — jump to next cell
- `:MarimoCellPrev` — jump to previous cell
- `:MarimoCellAddBelow` — add cell below current cell
- `:MarimoCellDelete` — delete current cell
- `:MarimoCellGoto <n>` — jump to cell number
- `:MarimoToggleView` — toggle hidden-boilerplate cell view

---

## Default keymaps

- `]c` — next cell
- `[c` — previous cell
- `<leader>ma` — add cell below
- `<leader>md` — delete current cell
- `<leader>mr` — run current cell
- `<leader>mR` — run notebook
- `<leader>mp` — start preview
- `<leader>mt` — toggle preview
- `<leader>mP` — stop preview
- `<leader>mv` — toggle cell-rendered view
- `<leader>mn` — create new notebook
- `<leader>mo` — `:MarimoOpen ...`
- `<leader>mO` — `:MarimoOpenTab ...`

Disable defaults with `keymaps = false`.

---

## Behavior details

- The plugin overlays `[Cell N]` markers where `@app.cell` appears.
- In normal mode, decorator/function boilerplate is hidden.
- On entering insert mode, boilerplate is shown so the file is fully editable.
- On leaving insert mode (or buffer/text events), view decorations refresh.

---

## Project structure

- `plugin/marimo.lua` — plugin entrypoint
- `lua/marimo/init.lua` — setup + autocmd wiring
- `lua/marimo/parser.lua` — marimo cell detection/parsing
- `lua/marimo/view.lua` — in-buffer cell visualization
- `lua/marimo/notebook.lua` — notebook/cell editing actions
- `lua/marimo/runner.lua` — marimo process/preview execution
- `lua/marimo/commands.lua` — user commands + keymaps
- `lua/marimo/util.lua` — helpers

---

## Notes

This is a practical first version focused on workflow in Neovim + browser marimo. Future improvements can include stronger AST-aware editing, persistent kernel/session integration, and tighter cell execution synchronization.
