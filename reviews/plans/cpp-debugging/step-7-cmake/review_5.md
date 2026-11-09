# Step 7 — Review 5 (defect found in step 8)

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 7 "CMake integration" (committed at `16e6854`) |
| Branch | `cpp-debugging` |
| Source | `step-8-e2e/review_1.md` |
| Date | 2026-11-09 |
| Verdict | **Changes requested.** `runInTerminal` (review 3, item A) broke ending a launched program. |

## Finding: Stop / `,DX` / Restart leave a launched program running — must fix

`templates/vimspector-cpp.json` and `lua/config/cmake_debug.lua` (Launch entries)

```jsonc
        "runInTerminal": true
```

**Comment:** With `runInTerminal`, lldb-dap launches the program through
`lldb-dap --launch-target` and **attaches** to it. Vimspector's non-interactive stop paths never
set `terminateDebuggee`:
- `Stop()` → `StopAllSessions(interactive=False)` (`debug_session.py:612-614`);
- `Reset()` without the flag, which is what `,DX` calls (`:630-633`);
- Restart (`:531`).

They all send `disconnect {}` (`_StopDebugAdapter`, `:1626-1630`), and lldb-dap detaches. Step 8
measured it:
- the program is still running 6 s after S-F5 or `,DX`;
- Restart leaves two instances;
- with `runInTerminal: false`, the same S-F5 gives `exited with status = 9 … killed`.

## Requirements for the fix

1. **Keep the colours.** The program's output stays in a real terminal (`runInTerminal`), unless
   you show that's impossible together with 2–3. In that case, stop and report the trade-off; the
   user decides.
2. **S-F5, `,DX` and C-S-F5 end a *launched* program.** No orphan, and Restart leaves exactly one
   instance.
3. **The same keys still only detach from an *attached* program** (step 6's requirement: never
   kill something the user attached to).
4. **Prefer configuration over Vimspector internals.** Investigate first, in this order:
   - lldb-dap launch-config options that make a bare `disconnect` terminate a runInTerminal
     launch. Check lldb-dap 22.1.8 (`lldb-dap --help`, `strings`, LLVM docs) for options such as
     `terminateCommands`, `exitCommands` or `disconnect` behaviour. Show whether a bare disconnect
     then kills the program, and whether there are ordering problems, e.g. detach happening before
     the commands run;
   - only if no option works: a small Lua wrapper used by S-F5 / `,DX` / C-S-F5 that sends
     `terminateDebuggee: true` for sessions whose request is `launch`. That means calling
     Vimspector's Python (`_vimspector_session` / `_StopNextSession`). It's private API, so keep it
     minimal, comment why, and fall back to the public call if the internals are missing.
5. **Fix the now-false statements:**
   - the `,DX` comment in `lua/plugins/vimspector.lua` ("terminates a launched one");
   - plan step 6's detach note ("terminate for launched ones");
   - add a short note to step 7 recording the defect and the fix.
6. **Verify** with the step-8 drivers (`scratchpad/step8/stop.lua`, `run.sh`):
   - Launch then S-F5 → process gone;
   - Launch then `,DX` → gone;
   - Launch then C-S-F5 → exactly one instance;
   - attach then S-F5 and `,DX` → still alive;
   - colours: the terminal buffer still has no raw `ESC[`;
   - breakpoints still bind;
   - repeat Launch + S-F5 on magister (`magister: Launch`), then check no `build/debug/magister`
     process is left.
   Kill only processes you started.

## Required before approval

- [ ] Fix per requirements 1–4, with the investigation results.
- [ ] Comments and plan corrected (5).
- [ ] Verification (6), with output.
