# vim.pack Migration Research

## Research Metadata

- Research date: 2026-04-09
- Evaluated against: Neovim 0.12 documentation and current `vim.pack` docs published in March 2026
- Config state reviewed from this repo on: 2026-04-09

This note is time-sensitive. A future Neovim release may expand `vim.pack` enough to remove some of the limitations and manual migration work described below.

## Summary

This repo currently uses `lazy.nvim` for plugin bootstrap, plugin specification, lazy-loading, dependency handling, build hooks, and lockfile management.

Neovim now includes a built-in plugin manager, `vim.pack`, documented in `:help pack` and on the official docs site:

- https://neovim.io/doc/user/pack/

At the time of review, the official docs describe `vim.pack` as "experimental, yet should be stable enough for daily use."

This note captures the migration implications for this repo. No migration has been performed.

## Current Repo Shape

The current entrypoint is:

- [`init.lua`](/Users/feliperobledo/src/vimconfig/init.lua)

It loads:

- [`lua/config/lazy.lua`](/Users/feliperobledo/src/vimconfig/lua/config/lazy.lua)

That file:

- bootstraps `lazy.nvim` by cloning it if missing
- prepends it to `runtimepath`
- calls `require("lazy").setup(...)`
- imports plugin specs from `lua/plugins`

Current plugin metadata is spread across `lua/plugins/*.lua`, where plugin specs use `lazy.nvim` fields such as:

- `event`
- `ft`
- `cmd`
- `dependencies`
- `build`
- `opts`
- `config`
- `init`

The current lockfile is:

- [`lazy-lock.json`](/Users/feliperobledo/src/vimconfig/lazy-lock.json)

## What `vim.pack` Does

`vim.pack` can:

- install plugins from Git repositories
- update plugins
- delete plugins
- maintain a built-in lockfile
- load plugins with `:packadd` semantics

Its lockfile is:

- `nvim-pack-lock.json`

Per the official docs, it should be treated as part of the config and committed to version control when using it seriously.

## What `vim.pack` Does Not Replace Automatically

`vim.pack` is not a drop-in replacement for `lazy.nvim`.

It does not directly consume `lazy.nvim` plugin spec tables or automatically replicate:

- declarative lazy-loading via `event`, `ft`, `cmd`, or `keys`
- dependency orchestration in the `lazy.nvim` style
- inline `config`/`opts` handling
- automatic plugin build hook behavior
- the current `lazy-lock.json` workflow

The migration would therefore be a structural rewrite of plugin management, not a one-line swap.

## Repo-Specific Migration Impact

### 1. Bootstrap Replacement

`lazy.nvim` bootstrap in [`lua/config/lazy.lua`](/Users/feliperobledo/src/vimconfig/lua/config/lazy.lua) would need to be replaced with a `vim.pack.add(...)` entrypoint.

Conceptually:

```lua
vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-telescope/telescope.nvim",
})
```

This is only the installation side. Runtime loading and configuration would still need to be handled separately.

### 2. Plugin Spec Restructuring

Today, many files under `lua/plugins` are both:

- installation declarations
- plugin configuration modules

With `vim.pack`, these concerns should be separated more explicitly:

- one registry of plugins to install/manage
- plain Lua modules for configuration
- explicit load timing where lazy-loading is still desired

### 3. Manual Lazy-Loading Would Be Required

Examples currently using `lazy.nvim` features:

- [`lua/plugins/nvim_cmp.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/nvim_cmp.lua) uses `event = "InsertEnter"`
- [`lua/plugins/trouble.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/trouble.lua) uses `cmd = "TroubleToggle"`
- [`lua/plugins/neodev.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/neodev.lua) uses `ft = { "lua" }`
- [`lua/plugins/fidget.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/fidget.lua) uses `event = "LspAttach"`

Under `vim.pack`, these would need to be recreated manually with `autocmd`, custom commands, or direct `packadd` calls.

Conceptually:

```lua
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    vim.cmd.packadd("nvim-cmp")
    require("plugins.cmp")
  end,
})
```

This example is illustrative only and was not implemented.

### 4. Dependencies Would Need Explicit Handling

Current `lazy.nvim` specs can declare dependencies inline.

Example patterns in this repo include:

- completion plugin depending on `cmp-*` sources and `lspkind`
- plugins like `trouble.nvim` or `none-ls.nvim` depending on other libraries

With `vim.pack`, dependencies still need to be installed, but config ordering becomes the user's responsibility.

The migration would need a deliberate load model rather than relying on `lazy.nvim` to coordinate it.

### 5. Build Hooks Need Special Treatment

This repo has plugins that currently rely on `build` directives, including:

- [`lua/plugins/nvim-treesitter.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/nvim-treesitter.lua) with `:TSUpdate`
- [`lua/plugins/nvim_gdb.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/nvim_gdb.lua) with `./install.sh`

The `vim.pack` docs describe using `PackChanged` autocmd hooks for install/update actions.

That means build/update tasks would need explicit hook logic.

### 6. Lockfile Workflow Would Change

The repo currently tracks plugin versions in [`lazy-lock.json`](/Users/feliperobledo/src/vimconfig/lazy-lock.json).

Under `vim.pack`, that would be replaced by:

- `nvim-pack-lock.json`

Operationally this changes:

- how plugin versions are recorded
- how updates are reviewed
- how versions are reverted
- how a fresh machine rehydrates plugin state

## Practical Migration Strategy If Revisited Later

If this idea is revisited, the safest path is:

1. Replace the bootstrap with `vim.pack.add(...)`.
2. Convert plugin specs into a plain install registry plus separate config modules.
3. Start with more eager loading than the current `lazy.nvim` setup.
4. Reintroduce manual lazy-loading only where startup impact matters.
5. Add explicit install/update hooks for plugins with build steps.
6. Replace `lazy-lock.json` with `nvim-pack-lock.json`.

This is safer than trying to preserve every `lazy.nvim` optimization immediately.

## Why We Dropped It For Now

The migration is possible, but the cost is higher than the benefit right now because:

- `vim.pack` is not a direct replacement for the current `lazy.nvim` spec model
- the repo would need structural changes, not just syntax changes
- manual lazy-load behavior would need to be rebuilt
- build hooks and dependency ordering would need explicit ownership
- the current config is already functional and mid-migration in other areas

The highest-friction part is not installation. It is replacing the runtime behavior currently encoded in `lazy.nvim` plugin specs.

## Key Official Reference

- Neovim package docs: https://neovim.io/doc/user/pack/
