# Step 6 — Review 2

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 6 "Attach to a running process" |
| Branch | `cpp-debugging` (uncommitted, on top of `342324d`) |
| Files reviewed | `lua/plugins/vimspector.lua` (`,DX`), `plans/cpp-debugging.md` (steps 1, 6, 9) |
| Previous review | `review_1.md` |
| Date | 2026-11-08 |
| Verdict | **Approved.** Ready to commit. The interactive checks on magister move into the user batch after step 7. |

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| `,DX` mapping | `maparg(",DX", "n")` | `<Cmd>call vimspector#Reset()<CR>` ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| No stray processes | `pgrep -fl "magister\|looper"` | none ✅ |
| Plan records the findings | `grep -n "programName\|pid#json\|40–50 ms\|non-interactive\|removed in step 6"` | step 1 note (l.91), step 6 picker (l.185-186), waitFor timing (l.209), detach/`,DX` (l.216) ✅ |
| Changed files | `git status --porcelain --untracked-files=all` | 4 modified + `review_1.md` ✅ |

## Review 1 items

### Finding 1 — `,DX` could kill an attached process: resolved

`lua/plugins/vimspector.lua`

```lua
    -- Non-interactive Reset: unlike :VimspectorReset it never asks "Terminate debuggee?".
    -- It sends a plain disconnect, so lldb-dap detaches from an attached process (leaving it
    -- running) and terminates a launched one.
    map("n", "<leader>DX", "<cmd>call vimspector#Reset()<cr>", { desc = "Debug: reset (detach / end session, close UI)" })
```

**Comment:** It was tested through the real mapping (`nvim_feedkeys(",DX", "mx")`), with
`utils.Confirm` patched to catch any prompt. Both cases came out as intended:

- **attach:** `confirm prompt: none`, `disconnect {}`, pid 84246 alive and its output grew from
  45 to 64 lines in 2 s;
- **launch:** `confirm prompt: none`, `disconnect {}`, `terminated` / `exited (exitCode 9)`, and
  no orphan process.

The comment explains the difference from `:VimspectorReset`, and the `desc` now says what the key
does in both cases.

### Findings 2 and 3 — plan corrections: resolved

**Comment:**
- Step 1's ticked lines stay as history, each with a "removed/changed in step 6" note. That
  includes a note under the key table for `,DX`, which the subagent added on its own and which is
  right, because that row still says `:VimspectorReset`.
- Step 6 now records the basename and anchored filter, `pid#json`, the waitFor timing measured on
  magister, and why `,DX` is non-interactive, each with a source citation.
- Step 9 has the new docs item for the Stop / Reset / `,DX` behaviour.

## New findings

None.

## Manual checks: deferred

The three manual checks from review 1 (filtered picker, triangle still rendering across
attach/continue/detach, the `:VimspectorReset` prompt) need a `.vimspector.json` in magister.
Step 7 generates that file and gitignores it. Doing the checks now would mean hand-creating an
untracked file in the user's repo, and setting it up twice. They go into the user batch after step
7. If any of them fails, it gets a follow-up review under this step's folder.

## Next actions (subagent)

- [ ] Tick every step-6 checkbox.
- [ ] Commit step 6: `templates/vimspector-cpp.json`, `lua/plugins/vimspector.lua`, `CLAUDE.md`,
      `plans/cpp-debugging.md`, `reviews/plans/cpp-debugging/step-6-attach/`.

## Step 6 checklist status

| Item | Status |
| --- | --- |
| `Attach (pick process)` config | ✅ |
| `Attach (wait for launch)` config | ✅ |
| `vimspector_process_list` built and found | ✅ |
| Attach by PID on magister | ✅ headless (`drawFrame`, locals); interactive picker → user batch |
| `waitFor` on magister | ✅ (`init()` line 334) |
| Detach leaves the game running | ✅ (Stop, `,DX`, Reset N/D); visual check → user batch |
| Hardened-runtime note in `CLAUDE.md` | ✅ |
