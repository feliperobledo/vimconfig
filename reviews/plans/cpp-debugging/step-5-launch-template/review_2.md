# Step 5 — Review 2

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 5 "Launch configuration template" |
| Branch | `cpp-debugging` (uncommitted, on top of `70fe429`) |
| Files reviewed | `plans/cpp-debugging.md` (+20 / −1) |
| Previous review | `review_1.md` |
| Date | 2026-11-08 |
| Verdict | **Approved.** Ready to commit. |

The round was interrupted once by a usage limit. The partial state was checked before resuming:
the plan had no edits, and the code was unchanged since review 1.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Code untouched this round | `cmp templates/vimspector-cpp.json <review-1 copy>`; `git diff --stat` | template identical; `commands.lua` still +32 ✅ |
| Plan lines added | `git diff -U0 plans/cpp-debugging.md` | 20 added lines ✅ |
| Rule appears in every place it's needed | `grep -n "breakpoints.exception" plans/cpp-debugging.md` | lines 73 (findings), 171 (step 5), 186 (step 6), 206 (step 7) ✅ |

## Review 1 items

### Finding 1 — carry the exception-block rule into the plan: resolved

`plans/cpp-debugging.md:69-75` (Findings carried into the plan)

```markdown
- Every `.vimspector.json` configuration (launch or attach, hand-written or generated) must carry
  a `breakpoints.exception` block answering lldb-dap's four filters (`cpp_throw`, `cpp_catch`,
  `objc_throw`, `objc_catch`). Without it Vimspector asks four Y/N questions on every launch
  (`breakpoints.py:1199-1215`); headless, that stalled the launch until it timed out. It can't go
  in the adapter: Vimspector reads it from the configuration entry only
  (`debug_session.py:2057-2058`), while the adapter's `configuration` merges into the DAP launch
  arguments.
```

**Comment:** This states the rule once, with its cause and both source citations, where anyone
starting step 6 or 7 will read it.

`plans/cpp-debugging.md`, steps 6 and 7

```markdown
- Each attach configuration needs the same `breakpoints.exception` block as `Launch`: Vimspector
  reads it per configuration only (`debug_session.py:2057-2058`), so it can't be shared through
  the adapter.
...
- Every generated configuration (launch and attach) carries the `breakpoints.exception` block
  from step 5 (per-configuration only, `debug_session.py:2057-2058`).
- Produce the generated `.vimspector.json` outright (e.g. `vim.json.encode` on a Lua table, then
  `write_vimspector_json` in `commands.lua`) rather than merging into the commented template:
  `vim.json.decode` can't read the template's comments.
```

**Comment:** Each note sits right under the items it qualifies, and they're plain bullets like
step 4's limitation note. Pointing step 7 at `write_vimspector_json` ties it to the helper this
step built for exactly that purpose. Step 5's own item now lists `request` and
`breakpoints.exception` with their reasons.

## New findings

None.

## Next actions (subagent)

- [ ] Tick every step-5 checkbox.
- [ ] Commit step 5: `templates/vimspector-cpp.json`, `lua/config/commands.lua`,
      `plans/cpp-debugging.md`, `reviews/plans/cpp-debugging/step-5-launch-template/`.

## Step 5 checklist status

| Item | Status |
| --- | --- |
| Template with generic `Launch` entry (+ `request`, + `breakpoints.exception`) | ✅ |
| `sourceMap` for remapping, never `initCommands` | ✅ |
| `:VimspectorInitCpp` with `!` overwrite rule | ✅ |
