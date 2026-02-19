# Neovim Modernization Plan

Roadmap for migrating this configuration to a fully Neovim-native stack built on built-in LSP, `mason.nvim`, and `nvim-cmp`. Work through the phases in order; each task uses Markdown checkboxes so progress is easy to track.

## Phase 1 — Baseline Audit

- [x] Catalog current language tooling (CoC extensions, ALE linters, OmniSharp settings) and identify which languages must continue working.
  - CoC (`neoclide/coc.nvim`) extensions: `coc-json`, `coc-tsserver`, `coc-eslint`, `coc-python`, `coc-pyls`, `coc-css`, `coc-highlight`, `coc-lua`, `coc-rust-analyzer`, `coc-sql` (JS/TS, JSON, ESLint, Python, Lua, Rust, SQL, CSS support).
  - ALE runs OmniSharp for C# linting (`vim.g.ale_linters = { cs = { "OmniSharp" } }` with explicit mode enabled).
  - OmniSharp Vim plugin configures C# server transport (`vim.g.OmniSharp_server_stdio = 1`, `vim.g.OmniSharp_server_use_mono = 1`).
  - Additional language helpers currently active: `vim-clang-format` (C/C++), `vim-polyglot` (syntax pack), `uiiaoo/java-syntax.vim`, `vim-ruby/vim-ruby`, `sakhnik/nvim-gdb` for debugging, `Epitrochoid/marko-vim-syntax` (GraphQL/Marko), `honza/vim-snippets`.
  - Globals referencing legacy tooling: `vim.g.coc_config_suggest_noselect = 1` in `lua/config/options.lua`.
- [x] Record existing keymaps and UI integrations that rely on CoC/ALE (e.g., `<leader>gf`, statusline segments, autocmds).
  - CoC keymaps are declared in per-language ftplugins (`ftplugin/javascript.vim`, `ftplugin/typescript.vim`, `ftplugin/python.vim`, `ftplugin/java.vim`) mapping to `<Plug>(coc-*)` actions for go-to-definition, references, diagnostics navigation.
  - C# ftplugin (`ftplugin/cs.vim`) binds numerous OmniSharp commands (`gd`, `<Leader>fi`, `<Leader>fs`, `<Leader>fx`, `<Leader>tt`, `<Leader>dc`, `<C-\\>`) and sets `CursorHold` autocmd for type lookup.
  - No explicit ALE statusline hooks found, but ALE is implicitly triggered via its default autocommands; note absence of custom keymaps to replicate diagnostic jumps later.
- [x] Snapshot the current `lazy-lock.json` and plugin specs so removals/additions can be verified later.
  - `lazy-lock.json` currently pins legacy tooling (`coc.nvim` @ `acaac49d5d3fe358ce0d67c91d78b1ada683d148`, `ale` @ `8c832181cfa91afd5a511cf45634225852b61682`, `omnisharp-vim` @ `c8f0f0ed811563beb6748ec425ee229c4fcf3388`).
  - Lazy setup resides in `lua/config/lazy.lua` and imports plugin specs from `lua/plugins/*.lua`; ensure this structure stays in sync during migration.
  - `lua/config/plugins.lua` still exists as a shim requiring `config.lazy`, so any references to `require("config.plugins")` remain functional for now.

## Phase 2 — Plugin Inventory Update

- [x] Add specs for the Neovim-native stack:
  - [x] `neovim/nvim-lspconfig` (`lua/plugins/nvim_lspconfig.lua`)
  - [x] `williamboman/mason.nvim` (`lua/plugins/mason.lua`)
  - [ ] `williamboman/mason-lspconfig.nvim` — intentionally skipped in favor of direct Mason registry installs.
  - [x] `hrsh7th/nvim-cmp` plus sources (`lua/plugins/nvim_cmp.lua`, `cmp_nvim_lsp.lua`, `cmp_buffer.lua`, `cmp_path.lua`, `cmp_cmdline.lua`, `cmp_luasnip.lua`)
  - [x] Snippet tooling (`lua/plugins/luasnip.lua`, `friendly_snippets.lua`)
  - [x] Optional helpers (`lua/plugins/neodev.lua`, `fidget.lua`, `trouble.lua`, `web_devicons.lua`)
- [x] Mark legacy tooling for removal (`neoclide/coc.nvim`, `dense-analysis/ale`, `OmniSharp/omnisharp-vim`) and decide if any niche features need replacements.
  - Legacy specs remain in `lua/plugins/coc.lua`, `ale.lua`, `omnisharp.lua` and will be deleted during Phase 7 after native replacements are verified.

## Phase 3 — Mason & LSP Bootstrap

- [x] Create `lua/config/lsp/init.lua` to own shared LSP utilities (`on_attach`, capabilities).
- [x] Initialize Mason in its plugin spec, enabling UI preferences and auto-install hooks via the registry.
- [x] Use the Mason registry to ensure required language servers are installed (Python, C#, JavaScript/TypeScript, Ruby, GraphQL, JSON, CSS, Rust, SQL).
- [x] Define a shared `on_attach` function for keymaps and buffer-local settings.
- [x] Generate capabilities via `require("cmp_nvim_lsp").default_capabilities()` for later use in server setups.
- [ ] After the Mason/LSP bootstrap is in place, run `:Lazy sync` to download the new tooling bundle.

## Phase 4 — Server Registration

- [ ] Plan server-specific settings so we can safely delete `coc.nvim`, `ale`, and `omnisharp-vim` during Phase 7 without losing features.
- [ ] For each language, register servers through `lspconfig.<server>.setup` with the shared `on_attach` and capabilities.
- [ ] Migrate OmniSharp-specific options (e.g., `use_mono`) into the new server definition or Mason config.
- [ ] Port ALE lint/format behavior either to native LSP settings or to external tools (consider `nvim-lint` or `null-ls` if needed).
- [ ] Confirm per-language features (formatting, diagnostics) load without CoC/ALE.

## Phase 5 — Completion & Snippets

- [ ] Set up `nvim-cmp` core config: snippet expansion, formatting, completion window styling.
- [ ] Add insert-mode mappings (`<Tab>`, `<S-Tab>`, `<CR>`) that mimic or improve upon the old CoC behavior.
- [ ] Enable context-specific sources (LSP + snippets in insert mode, buffer/path in command-line modes).
- [ ] Load snippet collections (e.g., `friendly-snippets`) and ensure they expand correctly.

## Phase 6 — UX Integration

- [ ] Rewrite CoC-driven keymaps to use `vim.lsp.buf` equivalents (definitions, references, rename, code actions).
- [ ] Update Telescope bindings to use new LSP pickers (`lsp_definitions`, `lsp_references`, `diagnostics`).
- [ ] Replace ALE diagnostic commands with `vim.diagnostic` mappings (float, next/prev, setloclist).
- [ ] Integrate optional UI enhancers (e.g., `fidget.nvim` for progress, `trouble.nvim` for diagnostics lists).

## Phase 7 — Cleanup & Validation

- [ ] Remove CoC, ALE, and OmniSharp Vim specs plus their remaining globals/config files.
- [ ] Delete unused CoC extension lists and ALE-specific autocmds.
- [ ] Run `:Lazy clean && :Lazy sync` to ensure only the new stack remains installed.
- [ ] Open representative projects (C#, JS/TS, Python, Ruby, GraphQL) and verify:
  - [ ] Language server auto-installs through Mason if missing.
  - [ ] Hover, completion, diagnostics, formatting, and snippets work as expected.
  - [ ] Keymaps trigger the new LSP-powered behavior without errors.
- [ ] Update `lazy-lock.json` after confirming the environment is stable.

## Phase 8 — Documentation & Follow-Up

- [ ] Document new workflows (formatting, diagnostics navigation) in the repo README or wiki.
- [ ] Capture any manual install steps (e.g., system dependencies for specific servers).
- [ ] Schedule periodic reviews of Mason-installed server versions and plugin updates.
- [ ] Archive this checklist once completed and convert remaining tasks into issues if needed.
