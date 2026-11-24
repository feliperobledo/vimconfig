# Step 8 — Review 2

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 8 "End-to-end verification" |
| Branch | `cpp-debugging` (at `8d9ef17`) |
| Previous review | `review_1.md` (blocked on the stop/restart defect) |
| Date | 2026-11-09 |
| Verdict | **Headless verification complete.** All 8 items pass. Waiting on the user's checklist in real Neovim before ticking and committing. |

## The blocking defect — resolved in step 7

The fix landed as `8d9ef17` (`step-7-cmake/review_5.md`, `review_6.md`): the Launch configs'
`terminateCommands` kill the program only when the session ended by detaching. It was re-verified
on step 8's own test program (`prog.cpp`, copied drivers in `scratchpad/step7/s8/`) and on
magister:

| Session | Key | Result |
| --- | --- | --- |
| Launch | S-F5 / `,DX` | program gone ✅ |
| Launch | C-S-F5 | exactly one instance ✅ |
| Attach | S-F5 / `,DX` | still running ✅ |
| magister Launch | S-F5 | `build/debug/magister` gone within 4 s ✅ |

The fix only adds a `terminateCommands` key to Launch configs. Items 1–3 and 5–8 don't depend on
how a session ends, and breakpoints were re-confirmed `VERIFIED` in those runs, so they stand
from review 1.

## Step 8 checklist status (headless)

| Item | Status |
| --- | --- |
| Single-file F9 + F5 | ✅ |
| Variables window, all std types incl. `expected` | ✅ |
| Watches and `,Di`; import-std-module off | ✅ |
| Stepping / run to cursor / pause / stop / restart | ✅ (stop/restart after `8d9ef17`) |
| Conditional + function breakpoints | ✅ |
| Signs with gitgutter | ✅ |
| Java unaffected | ✅ |
| Clean startup / health | ✅ |

## Waiting on the user

The consolidated checklist below was sent to the user. Results go in `review_3.md`. Then the
step-8 subagent ticks the boxes and commits `step-8-e2e/`.

1. **Launch, colours, stop:** `F5` → `magister: Launch`. spdlog colours render in the program's
   terminal window. `S-F5` closes the game window.
2. **Restart:** during a launch, `C-S-F5` restarts, and only one game window is open afterwards.
3. **Pause:** while rendering, `F6` stops (stack shown); `F5` resumes rendering.
4. **Edit and rebuild:** a real edit in `src/main.cpp`, then `:CMakeDebug magister` rebuilds,
   launches, and the breakpoint binds.
5. **Compile error:** a deliberate error, then `:CMakeDebug` → no session starts, quickfix shows
   the error, `<CR>` jumps to it.
6. **Attach:** `cd build/debug && ./magister`, then `F5` → `magister: Attach (pick process)`. The
   list shows only `magister`, PID pre-filled → breakpoint at 1476 stops → `,DX`. The game keeps
   rendering.
7. **Reset prompt (attached):** attach again, `:VimspectorReset` → N. The game keeps running.
8. **Signs:** `F9` on a gitgutter-marked line shows `●` and `~` side by side.
9. **`,Di`:** stopped, `,Di` on a variable shows a popup with its value.
