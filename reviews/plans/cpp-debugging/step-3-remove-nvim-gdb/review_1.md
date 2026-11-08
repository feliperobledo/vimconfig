# Step 3 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 3 "Remove `nvim-gdb`" |
| Branch | `cpp-debugging` (uncommitted, on top of `8dd3537`) |
| Files reviewed | `lua/plugins/nvim_gdb.lua` (deleted), `lazy-lock.json` (−1) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** The removal is correct; one plan addition needed for a stale doc reference. |

## Summary

The removal is clean and was done carefully:
- Before running `:Lazy clean`, the subagent checked lazy's `to_clean` list and confirmed
  `nvim-gdb` was the only entry.
- The lockfile lost exactly one line, and the plugin directory is gone.
- No code anywhere referenced the plugin.
- `,d` is now the only mapping with that prefix in every mode. The subagent also checked select
  mode and buffer-local mappings in a `.cpp` buffer, more than was asked.

The one gap: a research doc now links to the deleted file, and the plan doesn't yet say who fixes
it.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files | `git status --short` | ` M lazy-lock.json`, ` D lua/plugins/nvim_gdb.lua` ✅ |
| Plugin dir removed | `ls -d ~/.local/share/nvim/lazy/nvim-gdb` | `No such file or directory` ✅ |
| Lockfile entry gone | `grep -c nvim-gdb lazy-lock.json` | `0` ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| `,d` prefix is unique | `nmap ,d` / `xmap ,d` / `omap ,d` | `n ,d "_d`, `v ,d "_d`, omap none ✅ |

## Findings

### 1. `lazy-lock.json` diff — no change

```diff
   "nvim-dap": { "branch": "master", "commit": "9e848e09a697ee95302a3ef2dd43fd6eb709e570" },
-  "nvim-gdb": { "branch": "master", "commit": "67abac716b626ece57f3a7c72121542f0b3edfe9" },
   "nvim-java": { "branch": "main", "commit": "9e8b842ea9eff3ebf25fb7360908ed4d4f87c56a" },
```

**Comment:** Exactly the one entry, written by lazy itself during `clean`. Nothing else in the
lockfile moved, so this commit doesn't quietly update any other plugin.

### 2. Research doc links to the deleted file — should fix (plan)

`research/vim-pack-migration.md:155-158`

```markdown
This repo has plugins that currently rely on `build` directives, including:

- [`lua/plugins/nvim-treesitter.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/nvim-treesitter.lua) with `:TSUpdate`
- [`lua/plugins/nvim_gdb.lua`](/Users/feliperobledo/src/vimconfig/lua/plugins/nvim_gdb.lua) with `./install.sh`
```

**Comment:** This is now wrong in two ways. The link points at a deleted file. And the list of
plugins with `build` directives misses the one step 1 added: Vimspector's `go build` of
`vimspector_process_list`. That's exactly the kind of hook this vim.pack research is warning
about, so the doc should say so. Step 9 owns doc updates, but its checklist doesn't mention this
file, so it would be forgotten. Don't edit the research doc now. Add a step-9 checkbox to the
plan: update `research/vim-pack-migration.md`'s build-hook list (remove `nvim_gdb.lua`, add
`vimspector.lua`'s `go build`).

`research/cpp-debugging.md` and the plan itself also mention `nvim-gdb`. Those references are
historical records of the decision and are already covered by step 9's "record the decisions"
item, so they need no new entry.

### 3. "`,d` fires without the `timeoutlen` delay" — evidence accepted

**Comment:** Neovim only waits after `,d` when another mapping in the same mode starts with `,d`.
The mapping table shows none in any mode, so `,d` runs as soon as `d` is pressed. That's
conclusive, so this doesn't need a timed check. The box can be ticked on that basis. If you
notice `,d` still pausing in daily use, report it and we'll look again.

## Required before approval

- [ ] Finding 2: add a step-9 checkbox to `plans/cpp-debugging.md` for updating
      `research/vim-pack-migration.md`'s build-hook list.

## Needs the user (manual)

None. Optional: press `,dd` in a normal buffer and confirm the line is deleted immediately.

## Step 3 checklist status

| Item | Status |
| --- | --- |
| Delete `lua/plugins/nvim_gdb.lua` | ✅ |
| `:Lazy clean`, gone from `lazy-lock.json` | ✅ |
| `,d` fires without delay | ✅ (mapping-table evidence, finding 3) |
