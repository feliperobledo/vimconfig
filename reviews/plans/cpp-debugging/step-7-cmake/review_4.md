# Step 7 — Review 4

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 7 "CMake integration" |
| Branch | `cpp-debugging` (uncommitted, on top of `1b87f41`) |
| Files reviewed | `lua/config/cmake_debug.lua` (+2), `templates/vimspector-cpp.json` (+4), `lua/config/options.lua` (+3), `plans/cpp-debugging.md` |
| Previous review | `review_3.md` |
| Date | 2026-11-08 |
| Verdict | **Approved.** Ready to commit. The user's remaining visual checks move to step 8, the real end-to-end run. |

The round was interrupted once by a usage limit. The state was checked before resuming: none of
A–C had been applied yet.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| `runInTerminal` in launch configs only | `grep -n runInTerminal lua/config/cmake_debug.lua templates/vimspector-cpp.json` | generator Launch entry (l.454) and template `Launch` (l.29) ✅ |
| Regenerated magister file | `grep -c '"runInTerminal": true' …/magister/.vimspector.json` | `2` (the two Launch entries) ✅ |
| Sign column | `nvim --headless -c 'lua print(vim.o.signcolumn)'` | `auto:2` ✅ |
| Definition of Done reworded | `sed -n '/^## Definition of Done/,$p'` | `engine.h:17` under `magister`, `engine.cpp:6` under the tests ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| No stray processes | `pgrep -lf 'lldb-dap\|nvim --headless\|build/debug/magister'` | none ✅ (a pattern that can't match the user's Copilot server) |
| magister state | `git -C …/magister status --short` | ` M .gitignore` only ✅ |

## Review 3 items

### A — raw ANSI codes in the Console: resolved

`lua/config/cmake_debug.lua`, `target_configurations`

```lua
      stopOnEntry = false,
      -- Output goes to a Vimspector terminal (a real TTY, so colours render), not the Console.
      runInTerminal = true,
```

`templates/vimspector-cpp.json`, `Launch`

```jsonc
        "stopOnEntry": false,
        // Runs the program in a Vimspector terminal window (a real TTY: colours render, stdin
        // works) instead of sending its output to the Console, which shows escape codes raw.
        "runInTerminal": true
```

**Comment:** The subagent proved the mechanism before changing any code:
- Vimspector advertises `supportsRunInTerminalRequest`;
- lldb-dap sends the reverse request (`lldb-dap --launch-target …/magister`, `kind: integrated`)
  and attaches;
- the breakpoint at `main.cpp:1476` binds;
- the terminal buffer holds the spdlog lines **with no raw `ESC[`**, which shows the terminal
  interpreted the escape codes.

It then re-ran all three entry points: magister Launch, the tests Launch (`[  PASSED  ] 1 test.`
in the terminal), and the template in a scratch dir. Attach configs are rightly left alone. The
Console now carries only lldb-dap's messages. Whether the colours *look* right can't be read
through the API, so that's for the user's eye in step 8.

### B — breakpoint hides gitgutter's marker: resolved

`lua/config/options.lua`

```lua
-- Up to two signs per line, so a breakpoint shows next to gitgutter's change marker instead of hiding it
vim.opt.signcolumn = 'auto:2'
```

**Comment:** The width table answers the question exactly:
- 2 cells with one sign per line, the same as before;
- 0 with no signs;
- 4 cells for the whole window only while some line has two (` ●~`, breakpoint first because the
  priorities still order them).

The whole-window shift is how Neovim's `auto:N` works, and the plan note records it.

### C — `engine.cpp` wording: resolved

**Comment:** The step-7 check and the Definition of Done now describe what is actually possible:
`engine.h:17` under the game, `engine.cpp:6` under the tests, and the `nm -C` evidence. The user's
Vulkan step-into confirmation is recorded with its date. The A and B notes sit under steps 5, 7
and 1 as asked.

## New findings

None.

## Moved to step 8 (user, real Neovim)

- [ ] Pause (`F6`) while rendering, then continue.
- [ ] `:CMakeDebug` after a real content edit.
- [ ] A deliberate compile error → quickfix.
- [ ] Attach picker (filtered to `magister`, PID pre-filled) → breakpoint → `,DX` leaves the game
      rendering.
- [ ] `:VimspectorReset` → "Terminate debuggee?" → N leaves the game running.
- [ ] Colours in the program's terminal window; the two-wide sign column with gitgutter.

## Next actions (subagent)

- [ ] Tick every step-7 checkbox **except** the magister `.gitignore` item (the user commits that
      in magister); mark that one done in the plan only after the user confirms.
- [ ] Commit step 7: `lua/config/cmake_debug.lua`, `lua/config/commands.lua`,
      `lua/config/options.lua`, `templates/vimspector-cpp.json`, `plans/cpp-debugging.md`,
      `reviews/plans/cpp-debugging/step-7-cmake/`.

## Step 7 checklist status

All items ✅ (headless evidence plus the user's first manual check), with the visual checks above
in step 8.
