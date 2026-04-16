# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Neovim configuration undergoing an active, planned migration from a CoC/ALE-based stack to a fully native Neovim LSP stack (lspconfig + mason + nvim-cmp). The migration plan is tracked in `nvim-modernization.md`.

## Architecture

**Entry point**: `init.lua` loads modules in order: `config.options` → `config.lazy` → `config.keymaps` → `config.commands`

**Key directories**:
- `lua/config/` — core modules (options, keymaps, commands, autocmds, graphql, lazy bootstrap)
- `lua/plugins/` — one file per plugin spec (loaded by lazy.nvim)
- `ftplugin/` — filetype-specific overrides (currently java, cpp, cs)

**Plugin manager**: lazy.nvim, bootstrapped in `lua/config/lazy.lua`. Run `:Lazy sync` to install/update, `:Lazy clean` to remove unused. Lock file: `lazy-lock.json`.

**LSP layer**: the repo relies on Neovim `0.12` LSP defaults plus Mason and `mason-lspconfig` automatic enablement. There is no shared `lua/config/lsp.lua` module anymore; language-specific behavior should be added only when a server actually needs an override.

**Completion**: nvim-cmp with sources: nvim_lsp (primary), buffer, path, cmdline. Configured in `lua/plugins/nvim_cmp.lua`. Tab/S-Tab/CR mappings.

**Formatting**: none-ls.nvim integrates external formatters — prettier, black, stylua, rubocop, sql_formatter, markdownlint, htmlbeautifier.

## Migration Status

The repo is past the initial native-stack migration. Active work now is mainly cleanup and validation:
- align docs with the Neovim `0.12` default-driven LSP model
- verify per-language behavior in real projects
- decide which transitional plugins and language-specific overrides still belong

When editing ftplugin files, prefer Neovim defaults unless a filetype needs a specific override. CoC-era `<Plug>(coc-*)` mappings should not be reintroduced.

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
3. Keep server wiring consistent with the current model: default to Mason plus `mason-lspconfig` auto-enable, and only add explicit setup when a server requires it

## Language Server Configuration

Most servers come from Mason plus `mason-lspconfig` auto-enable rather than a shared custom LSP module. Exceptions:
- **GraphQL/Apollo**: custom setup in `lua/config/graphql.lua` (non-Mason path)
- **Java**: `nvim-java` handles the Java LSP lifecycle — see `lua/plugins/nvim-java.lua`
