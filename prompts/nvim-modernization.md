# Neovim Modernization Plan

Synchronized to the current repo state on April 16, 2026. This version reflects the live codebase plus recent git history, not the earlier target architecture that has since changed.

## Current Status

The migration is no longer at the "install the native stack" stage. That work is mostly done:

- [x] `lazy.nvim` is the plugin manager (`lua/config/lazy.lua`).
- [x] Native LSP plugins are present: `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig.nvim`.
- [x] Native completion is present: `nvim-cmp`, `cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`, `cmp-cmdline`, `lspkind`.
- [x] Tree-sitter is installed and configured (`lua/plugins/nvim-treesitter.lua`).
- [x] `none-ls.nvim` is present for formatter/diagnostic integration (`lua/plugins/none-ls.lua`).
- [x] Legacy CoC config has been removed from the repo: `coc-settings.json` is gone, CoC keymaps were stripped from `ftplugin/*.vim`, and the old `vim.g.coc_config_suggest_noselect` option is gone.
- [x] Legacy CoC/ALE/OmniSharp Vim plugin specs are already absent from `lua/plugins/` and from the current `lazy-lock.json`.

What remains is mostly consolidation, validation, and cleanup of stale assumptions.

## Git Milestones Already Landed

- [x] `73bbf98` migrated the config to Lua.
- [x] `513d49c`, `8c03008`, `954b73a`, `f60bb2d` introduced the native stack and removed CoC-era dependencies from the active setup.
- [x] `ef28f39` and `f97153e` improved the `nvim-cmp` UX.
- [x] `73f3dda` prepared for Neovim `0.12`: removed `coc-settings.json`, rewrote the C# ftplugin in Lua, and removed old CoC mappings from JS/TS/Python/Java ftplugins.
- [x] `948c41c` intentionally removed `lua/config/lsp.lua` and custom shared LSP mappings in favor of Neovim defaults.
- [x] `a0494eb` added `research/vim-pack-migration.md` for a possible future plugin-manager migration.

## Reality Check Against The Old Plan

The previous plan is stale in these ways:

- [x] It refers to files that no longer exist, especially `lua/config/lsp.lua` and `lua/config/lsp/servers/*`.
- [x] It assumes CoC, ALE, and `omnisharp-vim` still need to be removed; they are already gone from the active plugin set.
- [x] It says CoC mappings still need to be rewritten; that work mostly landed in `73f3dda`.
- [x] It assumes there is a shared `on_attach`/capabilities layer today; there is not.

## Remaining Modernization Work

### Phase 1 — Standardize On Neovim 0.12 Defaults

- [x] Architectural direction: rely on Neovim `0.12` LSP defaults plus `mason-lspconfig` automatic enablement instead of reintroducing a shared custom LSP module.
- [x] Update ftplugin comments that still reference deleted `lua/config/lsp.lua`.
- [x] Audit the config for places that still assume a shared `on_attach` / capabilities layer exists and remove those assumptions.

Why this phase exists:

- `948c41c` intentionally removed the custom shared LSP layer.
- `lua/plugins/mason.lua` is now the main place that determines installed and auto-enabled servers.
- Several docs and comments still describe the pre-`948c41c` setup instead of the current default-driven model.

### Phase 2 — Define Actual Server Ownership

- [x] Document which language path is authoritative for each filetype:
  - [x] Java: `nvim-java`.
  - [x] Mason-managed native LSP languages: C#, JS/TS, Python, Ruby, Lua, SQL, C/C++.
- [x] GraphQL is not part of the active workflow right now; no active GraphQL LSP path is required until that work resumes.
- [x] C# should use the same Neovim-default LSP UX as the other Mason-managed languages; no C#-specific keymap layer remains.
- [x] C# does not need explicit OmniSharp settings beyond the current default Mason-managed setup.
- [ ] Verify the Mason package names still match the intended servers and tools in `lua/plugins/mason.lua`.
- [ ] Decide whether `none-ls` or LSP should own formatting on a per-language basis.

### Phase 3 — Remove Dormant Config

- [x] Delete `lua/config/autocmd.lua` instead of reconnecting it. Its indentation logic belongs in `ftplugin/`, and the file was not loaded by `init.lua`.
- [x] Delete `lua/config/graphql.lua` instead of reconnecting it. GraphQL is not part of the active workflow right now, and it can be reintroduced later with an intentional setup.
- [ ] Remove or update dead comments that describe behavior that is not wired up anymore.

### Phase 4 — UX Integration

- [x] Baseline decision: Neovim default LSP mappings are the standard path unless a language-specific override is justified.
- [ ] Add Telescope LSP pickers to keymaps if desired (`lsp_definitions`, `lsp_references`, diagnostics-related pickers).
- [ ] Add explicit `vim.diagnostic` keymaps if the default UX is not enough.
- [ ] Either configure Trouble usage properly or remove it from the modernization target.
- [x] Remove `ftplugin/cs.lua` custom C# mappings so C# follows the same LSP defaults as other Mason-managed languages.

### Phase 5 — Validation

- [ ] Run through representative projects and confirm the current stack actually works end to end:
  - [ ] C#
  - [ ] Java
  - [ ] JavaScript / TypeScript
  - [ ] Python
  - [ ] Ruby
  - [ ] SQL
  - [ ] C / C++
- [ ] Verify:
  - [ ] LSP attach behavior
  - [ ] completion quality
  - [ ] diagnostics navigation
  - [ ] formatting source
  - [ ] hover / definition / references / rename / code actions
- [ ] Only refresh `lazy-lock.json` after the configuration is intentionally settled.

### Phase 6 — Documentation Cleanup

- [x] Update `README.md` so it no longer references deleted `lua/config/lsp/servers/*` structure.
- [ ] Update `CLAUDE.md` to stop referencing deleted files and incomplete migration assumptions.
- [ ] Document the final operating model once the LSP ownership and keymap decisions are settled.

## Deferred / Optional Follow-Up

- [ ] Decide whether to keep transitional legacy plugins such as `ag.nvim`, `FlyGrep.vim`, `ctrlsf.vim`, `vim-gitgutter`, `vim-clang-format`, and `vimspector`, or replace/remove them as part of a broader cleanup.
- [ ] Evaluate `rcarriga/nvim-dap-ui` if the debugging stack is modernized further.
- [ ] Keep `research/vim-pack-migration.md` separate from the LSP modernization effort; that is a later plugin-manager decision, not part of core feature parity.

## Notes

- `lazy-lock.json` is currently modified in the worktree. Do not treat the checked-in lockfile as finalized until validation is complete.
- The intended LSP model is now Neovim `0.12` defaults plus `mason-lspconfig`, not a custom shared `on_attach` layer.
- The biggest gap today is mostly documentation and validation drift: several docs/comments still assume the old shared LSP module exists.
