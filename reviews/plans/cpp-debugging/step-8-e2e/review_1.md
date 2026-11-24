# Step 8 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 8 "End-to-end verification" |
| Branch | `cpp-debugging` (clean, at `16e6854`; step 8 changes no files) |
| Scope reviewed | Headless verification report; scratch drivers in `scratchpad/step8/` |
| Date | 2026-11-09 |
| Verdict | **Blocked by a defect introduced in step 7.** 7 of 8 items pass. Stop / `,DX` / Restart leave a *launched* program running. The fix goes back to step 7 (`step-7-cmake/review_5.md`); step 8 is re-verified after it lands. |

## Summary

The verification is thorough, and it ran through the real mappings with each `maparg` logged.
Vimspector's prompts can't be answered by typeahead from the py3 host, so they were answered by
patching `SelectFromList` / `AskForInput`, while the real mapping still triggered each prompt.
That's the right compromise.

| # | Item | Result |
| --- | --- | --- |
| 1 | F9 + F5, stops with correct locals | ✅ |
| 2 | Variables window renders all std types incl. `expected` (closes the step-2 deferral) | ✅ |
| 3 | Watches, `,Di` (n + x), `import-std-module` off | ✅ (hover can't do arithmetic: lldb-dap limit) |
| 4 | Step over/into/out, run to cursor, pause, stop, restart | ❌ stop and restart leave the launched program running |
| 5 | Conditional (`,F9`, `i == 3`) and function (`F8`, `square`) breakpoints | ✅ |
| 6 | Breakpoint + gitgutter signs side by side via the real F9 | ✅ |
| 7 | Java via nvim-dap still works; no new Java keymaps | ✅ (a real breakpoint stop in `Main.main`) |
| 8 | Clean startup; health | ✅ (Vimspector ships no healthcheck) |

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Repo untouched | `git status --short` | clean ✅ (the stray `x` the subagent created and deleted is gone) |
| No leftover test programs | `pgrep -lx prog` | none ✅ |
| Why Stop can't terminate | `debug_session.py:598-614`, `:1626-1630`, `:1660-1681` | see the defect below |

## Defect: Stop / `,DX` / Restart don't end a launched program (`runInTerminal`)

Evidence from `stopf5.out` / `stopdx.out`, the same with S-F5 and `,DX`:

```
[stopped]        51652 SNXs+ 0:00.02 prog loop
[3s after S-F5]  51652 RNs+  0:03.11 prog loop
[6s after S-F5]  51652 RNs+  0:06.16 prog loop
```

Control (`stopf5_nort.out`, same config with `"runInTerminal": false`):

```
Process 52128 exited with status = 9 (0x00000009) killed
```

After `C-S-F5` (Restart), two `prog` processes were alive: the old one survived.

**Cause, from the source:** Vimspector's non-interactive paths, `Stop()` (`:612-614`), `Reset()`
without the flag (`:630-633`) and Restart (`:531`), all call `_StopNextSession(None, …)`. That
sends `disconnect` with **no** `terminateDebuggee` (`_StopDebugAdapter`, `:1626-1630`). Only the
interactive `_ConfirmTerminateDebugee` (`:1660-1681`) ever sets it to `true`. With
`runInTerminal`, lldb-dap starts the program through `lldb-dap --launch-target` and then
*attaches* to it, so its default for a bare disconnect is to detach. Before step 7's
`runInTerminal`, launch sessions were real launches, and a bare disconnect terminated them. That's
why step 6's tests (which predate `runInTerminal`) passed.

**Impact on magister:** S-F5 or `,DX` leaves the game window running headless of any debugger, and
C-S-F5 starts a second instance each time.

**Statements that are now false:** the step-6 plan note ("terminate for launched ones") and the
`,DX` comment in `lua/plugins/vimspector.lua` ("terminates a launched one").

**Routing:** this is step-7 code, so it goes to the step-7 subagent as
`step-7-cmake/review_5.md`. Requirements: keep the colours (`runInTerminal`), make Stop, `,DX`
and Restart end a *launched* program, and keep detach-only for *attached* ones.

## Other observations — no change

- `std::string` rows keep a `+` that expands to raw libc++ internals. That's lldb-dap's
  presentation; the summary line is right.
- `,Di` on an arithmetic selection shows lldb-dap's hover parse error. Hover evaluates
  variable/member paths only; watches do arithmetic. Worth a line in step 9's docs.
- `:checkhealth vimspector` → "No healthcheck found": Vimspector doesn't ship one. The relevant
  provider check (pynvim 0.6.0) passes. The plan item says "if available", so this is satisfied.

## User checklist

Held until the fix lands and step 8 is re-run, so the user checks the final behaviour once.

## Step 8 checklist status

| Item | Status |
| --- | --- |
| Single-file F9 + F5 | ✅ |
| Variables window, all std types | ✅ |
| Watches and `,Di`; import-std-module off | ✅ |
| Stepping / run to cursor / pause / stop / restart | ❌ defect (stop, restart) → step 7 review 5 |
| Conditional + function breakpoints | ✅ |
| Signs with gitgutter | ✅ |
| Java unaffected | ✅ |
| Clean startup / health | ✅ |
