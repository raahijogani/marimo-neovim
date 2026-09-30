# AGENTS.md

This repository is a Neovim plugin project.

## Mission

Build and maintain `marimo.nvim`: a plugin that turns Neovim into a cell-centric editor for Python marimo notebooks, while marimo runs in the browser as preview/runner.

## Product goals

1. Recognize marimo notebook source format in `.py` buffers.
2. Render notebook cells clearly in Neovim by labeling cells with indices.
3. Hide marimo boilerplate (`@app.cell`, `def __():`) in normal mode.
4. Reveal full raw code in insert mode for editing.
5. Provide notebook workflow commands:
   - Jump next/prev/goto cell
   - Add/remove cells
   - Run current cell
   - Run entire notebook
   - Start/stop/status preview server
   - Create new notebook
   - Open existing notebook in current buffer or a new tab
6. Keep plugin API simple through `require("marimo").setup({...})`.

## Current architecture

- `plugin/marimo.lua`
  - Plugin bootstrap/guard
  - Calls setup so commands are available by default

- `lua/marimo/init.lua`
  - Public setup entrypoint
  - Registers autocmds and optional keymaps

- `lua/marimo/parser.lua`
  - Detects marimo buffers and parses cells from text lines

- `lua/marimo/view.lua`
  - Applies extmarks for cell labels and conceal behavior
  - Hides boilerplate in normal mode, reveals in insert mode

- `lua/marimo/notebook.lua`
  - Notebook creation/opening
  - Cell navigation and structural edits

- `lua/marimo/runner.lua`
  - marimo CLI process integration
  - Run notebook/run cell/start/stop preview

- `lua/marimo/commands.lua`
  - User commands and default keymaps

- `lua/marimo/util.lua`
  - Notification and utility helpers

## Development guidance

- Keep Lua modules focused and composable.
- Preserve clean command UX and sane defaults.
- Prefer buffer-local/context-aware behavior for marimo notebooks.
- Ensure edits are safe when notebook format is imperfect.
- Validate Lua syntax after changes (`luac -p`).

## Future roadmap

- More robust parser (AST/tree-sitter based)
- Better single-cell execution semantics
- Session-aware run/preview management across buffers
- Optional browser pane integration through external tools
- Improved text objects/motions for cells
- Tests and CI (headless Neovim tests)
