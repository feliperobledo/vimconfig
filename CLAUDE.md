# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Neovim configuration undergoing an active, planned migration from a CoC/ALE-based stack to a fully native Neovim LSP stack (lspconfig + mason + nvim-cmp). The migration plan is tracked in `nvim-modernization.md`.

## Architecture

**Entry point**: `init.lua` loads modules in order: `config.options` → `config.lazy` → `config.keymaps` → `config.commands`

**Key directories**:
- `lua/config/` — core modules (options, keymaps, commands, autocmds, lsp, lazy bootstrap)
- `lua/plugins/` — one file per plugin spec (loaded by lazy.nvim)
- `ftplugin/` — filetype-specific overrides (js, ts, python, java, cpp, cs)

**Plugin manager**: lazy.nvim, bootstrapped in `lua/config/lazy.lua`. Run `:Lazy sync` to install/update, `:Lazy clean` to remove unused. Lock file: `lazy-lock.json`.

**LSP layer**: `lua/config/lsp.lua` owns shared `on_attach()` and capabilities (from `cmp_nvim_lsp`). Language servers are installed via Mason and registered via mason-lspconfig. The `on_attach` function sets buffer-local omnifunc and standard LSP keymaps (`gd`, `gr`, `gI`, `K`, `<leader>rn`, `<leader>ca`, `<leader>f`, `[d`/`]d`).

**Completion**: nvim-cmp with sources: nvim_lsp (primary), buffer, path, cmdline. Configured in `lua/config/cmp.lua`. Tab/S-Tab/CR mappings.

**Formatting**: none-ls.nvim integrates external formatters — prettier, black, stylua, rubocop, sql_formatter, markdownlint, htmlbeautifier.

## Migration Status

Phases 1–3 and 5 are complete. Active work areas per `nvim-modernization.md`:
- **Phase 4 (incomplete)**: per-language feature parity — CoC keymaps not yet replicated in ftplugin files; OmniSharp mono/stdio flags need migration
- **Phase 6**: CoC-driven keymaps in ftplugins (`<Plug>(coc-*)`) still present in `ftplugin/*.vim` — these need to be rewritten to `vim.lsp.buf` equivalents
- **Phase 7**: `coc-settings.json` and legacy references (`vim.g.coc_config_suggest_noselect` in options.lua) still present; CoC/ALE plugin specs to be removed after verification
- **Phase 8**: Docs and follow-up

When editing ftplugin files, prefer `vim.lsp.buf.*` over any `<Plug>(coc-*)` references. The goal is to eliminate all CoC dependencies.

## Common Operations

**In Neovim**:
- `:Lazy sync` — install/update all plugins
- `:Lazy clean` — remove unused plugins
- `:TSUpdate` — update treesitter parsers
- `:Mason` — open Mason UI to manage language servers
- `:checkhealth` — diagnose configuration issues

**Session management**: F2 saves session, F3 loads (`Session.vim` via obsession).

**Key leader**: `,` (both `mapleader` and `maplocalleader`)

## Plugin File Conventions

Each plugin lives in its own file under `lua/plugins/`. When adding a new plugin:
1. Create `lua/plugins/<name>.lua` returning a lazy.nvim spec table
2. Use `dependencies` to declare ordering requirements
3. LSP server configs belong in the mason-lspconfig `handlers` table in `lua/plugins/mason_lspconfig.lua`, not as standalone `lspconfig.<server>.setup()` calls

## Language Server Configuration

Servers are registered through mason-lspconfig handlers. All servers receive the shared `on_attach` and capabilities from `lua/config/lsp.lua`. Exceptions:
- **GraphQL/Apollo**: custom setup in `lua/config/graphql.lua` (non-Mason path)
- **OmniSharp (C#)**: `omnisharp_extended` plugin wraps lspconfig for better go-to-definition — see `lua/plugins/omnisharp_extended.lua`
- **Java**: `nvim-java` plugin handles the full Java LSP lifecycle — see `lua/plugins/nvim_java.lua`
