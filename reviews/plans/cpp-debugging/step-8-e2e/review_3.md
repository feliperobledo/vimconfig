# Step 8 — Review 3 (user results)

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 8 "End-to-end verification" |
| Branch | `cpp-debugging` (at `3a28e39`; the user's own `feat: bump deps` sits on top of `8d9ef17`) |
| Previous review | `review_2.md` (headless complete, waiting on the user) |
| Date | 2026-11-24 |
| Verdict | **Approved.** All 9 user checks pass; the Reset-N trade-off is accepted. |

## User checklist results

| # | Check | Result |
| --- | --- | --- |
| 1 | Launch, colours in the terminal window, S-F5 closes the game | ✅ |
| 2 | C-S-F5 leaves exactly one game window | ✅ |
| 3 | F6 pauses while rendering, F5 resumes | ✅ |
| 4 | Real edit → `:CMakeDebug magister` rebuilds, launches, breakpoint binds | ✅ |
| 5 | Compile error → no session, quickfix, `<CR>` jumps | ✅ |
| 6 | Attach picker filtered to `magister`, PID pre-filled → breakpoint → `,DX` leaves it rendering | ✅ |
| 7 | Attached, `:VimspectorReset` → N leaves the game running | ✅ |
| 8 | Breakpoint and gitgutter signs side by side | ✅ after re-saving the session (below) |
| 9 | `,Di` popup | ✅ |

### Item 8: stale session option, not a config defect

At first only one sign showed per line. A fresh `nvim` reports `signcolumn=auto:2`, last set from
`init.lua`. The cause was magister's `Session.vim`:
- `sessionoptions` includes `localoptions`, so the session records each window's own settings;
- the file was saved before step 7, so it holds `setlocal signcolumn=auto` (lines 121, 256, 392);
- F3 restored that old value.

The user fixed it by setting `auto:2` in the restored windows and re-saving with F2, after which
item 8 passed. `localoptions` is kept, because removing it would stop sessions restoring other
per-window settings. Step 9's docs should mention that a session saved before a window-option
change restores the old value until it's re-saved.

## Decision recorded

**`:VimspectorReset` → N ends a *launched* program** (consequence of `8d9ef17`): accepted by the
user. Attach is the way to keep a program running after detaching.

## Next actions (subagent)

- [ ] Tick every step-8 checkbox.
- [ ] Commit step 8: `plans/cpp-debugging.md` and `reviews/plans/cpp-debugging/step-8-e2e/` only.
      **Don't stage** the user's uncommitted `lua/config/keymaps.lua` or
      `.claude/settings.local.json`.
