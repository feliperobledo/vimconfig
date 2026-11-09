# Step 7 — Review 3 (user results + follow-ups)

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 7 "CMake integration" |
| Branch | `cpp-debugging` (uncommitted, on top of `1b87f41`) |
| Previous review | `review_2.md` (code approved, on hold for the user) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** The user's decision and first manual check are in. Two follow-ups from the user's real session, plus the `engine.cpp` rewording. |

## User results

### Decision on finding 1 (`engine.cpp`)

The user chose **"no need" to change magister**. They confirmed they could step into the Vulkan
API from magister, so stepping into library code works. Reword the `engine.cpp` checks and the
Definition of Done, as review 1 recommended.

### Manual check 1: launch and breakpoint ✅

The user pressed F5 (the game launched), then F9 on `main.cpp` line ~1477 while it ran, then F5
again, and the breakpoint triggered. A breakpoint set while the program is running is sent live,
so this also covers adding breakpoints mid-session.

Manual checks 2–6 (pause, `:CMakeDebug` after a real edit, build-error quickfix, attach picker +
`,DX`, `:VimspectorReset` N) are **still outstanding**. Check 7 (feel of a long first configure)
was optional and is **dropped**: the user doesn't need to rebuild from scratch.

## Follow-ups from the user's session

### A. The debug console shows raw ANSI escape codes — should fix

What the user saw in Vimspector's Console window:

```
[2026-11-08 18:56:25.005] [Init] [ [36mdebug [m] Draw Fence Created
[2026-11-08 18:56:48.538] [Vulkan] [ [33m [1mwarning [m] TESTING
```

A normal terminal renders the same spdlog output in colour.

**Comment:** Vimspector's Console is a plain text buffer, so it can't interpret colour escape
codes. The program's output should go to a real terminal instead. lldb-dap 22.1.8 supports DAP's
`runInTerminal` reverse request (`strings lldb-dap`: `runInTerminal`, `runInTerminal launcher`,
"Cannot use runInTerminal, feature is not supported by the connected client"). Vimspector
implements it too (`debug_session.py:2081`, `OnRequest_runInTerminal`), opening a terminal
window. With `"runInTerminal": true` in a launch configuration, the program should run in that
terminal, with colours and a real TTY. To do:

1. Verify that this works with Vimspector + lldb-dap: Vimspector advertises
   `supportsRunInTerminalRequest`, the program's output lands in a terminal buffer, and
   breakpoints still bind. Use magister headlessly and check the terminal buffer contains the log
   lines.
2. If it works, add `"runInTerminal": true` to the generated launch configs **and** to the
   template's `Launch`. Attach configs don't need it. Regenerate magister's `.vimspector.json`.
3. Check what happens to stdout/stderr in Vimspector's Console afterwards. It probably only shows
   lldb-dap's own messages, which is fine; say what you see.
4. If it doesn't work, explain why, and propose an alternative. Don't strip escape codes from the
   output.

### B. Breakpoint signs hide gitgutter's change markers — should fix

The user's recording shows a line with a gitgutter "changed" marker. Setting a breakpoint replaces
the marker with the breakpoint sign, and the marker comes back when it's cleared.

**Comment:** This is the sign-priority choice from step 1: breakpoints at 12 beat gitgutter's 10,
so a breakpoint is never hidden. But `signcolumn` is never set in this config (`grep -rn
signcolumn lua/ init.lua` → nothing), so Neovim's default `auto` shows **one** sign per line. Both
can show side by side with `vim.opt.signcolumn = "auto:2"`: the column only grows to two signs
where a line has two. Put it in `lua/config/options.lua`, matching that file's style, with a short
"why" comment. Keep the priorities, so the breakpoint stays in the first slot. Verify with
`sign_getplaced` on a buffer that has both a gitgutter sign and a breakpoint on the same line.
Report whether the column width changes in buffers with only one sign per line.

### C. `engine.cpp` wording — should fix (doc)

Reword the step-7 `engine.cpp` check and the Definition of Done's "break in `magister_engine`
code":
- under `magister`, library code is hit through `engine.h:17` (the inline constructor). Nothing
  from `engine.cpp` is linked into the game (`nm -C build/debug/magister`);
- under `magister_engine_tests`, `engine.cpp:6` binds and stops;
- the user confirmed stepping into the Vulkan API works.

## Required before approval

- [ ] A: `runInTerminal` verified and added to the generated launch configs and the template; or
      a reasoned alternative.
- [ ] B: `signcolumn = "auto:2"` in `lua/config/options.lua`; verified.
- [ ] C: plan wording for `engine.cpp` and the Definition of Done.
- [ ] Plan: add A and B as notes or items where they belong (A under steps 5/7, B under step 1's
      sign-priority item).

## Still needs the user

- [ ] Manual checks 2–6 from review 1 (pause, real-edit `:CMakeDebug`, build-error quickfix,
      attach picker + `,DX`, `:VimspectorReset` N), and a look at the program output in the new
      terminal (colours) and at the two-wide sign column, once A and B land.
