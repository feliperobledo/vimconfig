# Step 7 — Review 6

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 7 "CMake integration" |
| Branch | `cpp-debugging` (uncommitted, on top of `16e6854`) |
| Files reviewed | `templates/vimspector-cpp.json` (+5 / −1), `lua/config/cmake_debug.lua` (+8), `lua/plugins/vimspector.lua` (comment), `plans/cpp-debugging.md` (steps 6 and 7) |
| Previous review | `review_5.md` |
| Date | 2026-11-09 |
| Verdict | **Approved.** The defect is fixed with configuration only; one small trade-off goes to the user. |

## Summary

The investigation went in the order asked, and each dead end is backed by evidence:
- **No lldb-dap option** makes a bare `disconnect` terminate a `runInTerminal` launch.
- **`terminateCommands: ["process kill"]` fails** with `error: process must be launched`,
  because the commands run *after* the detach.
- **A probe showed lldb still knows the pid**, in state `detached`.

So the fix kills the remembered pid only when the session ended by detaching:

```jsonc
        "terminateCommands": ["script import os, signal; p = lldb.debugger.GetSelectedTarget().GetProcess(); os.kill(p.GetProcessID(), signal.SIGKILL) if p.GetState() == lldb.eStateDetached else None"]
```

This uses no Vimspector internals, and the Lua-wrapper fallback wasn't needed. It's only on
**Launch** configs, so attach configs still just detach. It's a separate key from the adapter's
`initCommands`, so the `std::expected` formatter still loads. After a normal exit the state is
`exited`, so nothing is killed. SIGKILL matches what lldb-dap itself does for a non-terminal
launch (`exited with status = 9`).

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files | `git status --porcelain --untracked-files=all` | 4 modified + the two review files ✅ |
| Only Launch entries carry it | `grep -c terminateCommands` | template 1, generator 2 (comment + use), magister file 2 (two Launch entries) ✅ |
| magister Launch + S-F5 | `r5_mag.out` | `70512 …/build/debug/magister` at stop → `none` 4 s and 7 s after S-F5 ✅ |
| Colours still interpreted | `r5_mag.out` | terminal buffer 86 lines, `0 with raw ESC[`; Console 0 ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| No stray processes | `pgrep -lf 'lldb-dap\|/build/debug/magister\|/p7/prog'` | none ✅ |

Matrix from the subagent's runs (`s8/l_*.out`, `s8/a_*.out`):

| Session | Key | Result |
| --- | --- | --- |
| Launch | S-F5 | 1 → 0 instances ✅ |
| Launch | `,DX` | 1 → 0 ✅ |
| Launch | C-S-F5 | 1 → exactly 1 (new pid) ✅; final S-F5 → 0 |
| Attach | S-F5 | alive, CPU time growing ✅ |
| Attach | `,DX` | alive, CPU time growing ✅ |
| tests Launch | runs to exit | `exited with status = 0`, terminateCommands harmless ✅ |

## Trade-off — the user decides; reviewer recommends accepting

`:VimspectorReset` → **N** ("don't terminate") now also ends a *launched* program:
`disconnect {"terminateDebuggee": false}`, then the process is gone. Leaving a launched program
running after the debugger goes away is no longer possible. The way to do that is to start it
yourself and use the attach configs, which still only detach. That seems the right default for a
game you launched from the debugger: an orphaned window is the worse outcome. The trade-off is
recorded in the plan's step-7 note.

## Statements corrected

- `,DX` comment in `lua/plugins/vimspector.lua`: now says launched programs are killed by the
  launch config's `terminateCommands`, and points to both files.
- Plan step 6: keeps what was true at step 6, then explains what changed in step 7.
- Plan step 7: a new note with the defect, the investigation, the fix and the Reset-N trade-off.

## New findings

None.

## Next actions (subagent)

- [ ] Commit the fix on `cpp-debugging`: `templates/vimspector-cpp.json`,
      `lua/config/cmake_debug.lua`, `lua/plugins/vimspector.lua`, `plans/cpp-debugging.md`,
      `reviews/plans/cpp-debugging/step-7-cmake/review_5.md`, `review_6.md`. Step 7's boxes are
      already ticked; don't change any others. The step-8 review is committed with step 8.
