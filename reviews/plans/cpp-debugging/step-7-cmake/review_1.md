# Step 7 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 7 "CMake integration" |
| Branch | `cpp-debugging` (uncommitted, on top of `1b87f41`) |
| Files reviewed | `lua/config/cmake_debug.lua` (new, 603 lines), `lua/config/commands.lua` (+38 / −2); magister `.gitignore` (+4, uncommitted) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** Works on magister end to end. One small guard, plan corrections, a re-run after the last edits, and one plan decision for the user. |

## Summary

This is the largest step, and it holds up. `:VimspectorInitCpp` in magister:
- picks the `debug` preset and resolves `build/debug`, cross-checked against CMake's own
  "Build files have been written to:";
- writes a stateless File API query, configures in 2.3 s, and finds exactly `magister` and
  `magister_engine_tests` out of 43 targets;
- generates six configurations that follow every rule from steps 5 and 6: exception block,
  `request`, `pid#json`, anchored `$$` filter, no `initCommands`, paths relative to
  `${workspaceRoot}`.

`:CMakeDebug` builds in the background and only starts the debugger on success, with errors in
quickfix (verified on a deliberately broken scratch project). On magister:
- launch stopped in the render loop with locals;
- pause landed in `acquireNextImage` → `drawFrame`;
- the GoogleTest body stopped;
- touch → rebuild → the breakpoint still bound;
- attach used `^magister$`, and `,DX` left the game running.

Several design decisions improve on the plan and are well argued:
- **Preset resolution with a clear failure** on unsupported macros, instead of guessing.
- **`-DCMAKE_BUILD_TYPE=Debug` only on the first configure** when there are no presets. Passing it
  every time would silently flip an existing Release build and make the refusal unreachable.
- **`args: []` instead of a prompt**, so a generated target starts in one step.
- **`:CMakeDebug` doesn't regenerate `.vimspector.json`.** Regenerating would discard edits.
- **`:CMakeDebug` uses its own target picker**, because Vimspector's picker hides every
  configuration when the current buffer is `CMakeLists.txt`.

The investigation also found two real problems outside the code: the `engine.cpp` breakpoint
(finding 1) and `vimspector#ClearBreakpoints()` (finding 4).

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files (vimconfig) | `git status --porcelain --untracked-files=all` | ` M lua/config/commands.lua`, `?? lua/config/cmake_debug.lua` ✅ |
| Changed files (magister) | `git -C …/magister status --short` | ` M .gitignore` only ✅ |
| No stray processes | `pgrep -lf 'lldb-dap\|magister\|nvim --headless'` | none ✅ |
| `engine.cpp` not linked into `magister` | `nm -C build/debug/magister \| grep magister::Engine` | only `magister::Engine::Engine()` (×2, inline ctor); no `Engine::name()` ✅ confirms finding 1 |
| Read the module in full | `lua/config/cmake_debug.lua:1-603` | see findings |

## Findings

### 1. `engine.cpp` can't be hit from `magister` — plan decision for the user

```
$ nm -C build/debug/magister | grep magister::Engine
0000000100018b88 t magister::Engine::Engine()
0000000100097448 t magister::Engine::Engine()
```

**Comment:** `main.cpp` only constructs `magister::Engine`, and the constructor is inline in
`engine.h`. Nothing in `magister` calls anything defined in `engine.cpp`, so the linker never
pulls `engine.o` out of `libmagister_engine.a`, and that breakpoint stays `PENDING`. This is a
fact about magister's code, not a debugger problem. The "library code" breakpoint *does* work:

- under `magister`, at `engine.h:17` (inline ctor in the library's public header);
- under `magister_engine_tests`, at `engine.cpp:6` (`Engine::name()`), which the test calls.

Two step-7 items and the Definition of Done say "break in `magister_engine` code" / "a
breakpoint in `src/engine/engine.cpp`". Either reword them to the above, or the user has magister
call into `engine.cpp`. **Reviewer recommendation: reword.** The goal is to prove library-code
breakpoints work, which they do. Waiting on the user's call; the subagent edits the plan after.

### 2. `:CMakeDebug` in a project without `CMakeLists.txt` — should fix

`lua/config/cmake_debug.lua:549-555`

```lua
function M.debug(root, target)
  if not check_ready() then
    return
  end
  if vim.fn.filereadable(root .. "/.vimspector.json") == 0 then
    return err("No .vimspector.json in " .. root .. ": run :VimspectorInitCpp first")
  end
```

**Comment:** `:VimspectorInitCpp` only takes the CMake path when `<cwd>/CMakeLists.txt` exists,
but `:CMakeDebug` never checks. In a plain project with a template-generated `.vimspector.json`,
it reports "No `<target>: Launch` configurations", which is misleading. If the file has been
hand-edited to have such a name, it would run `cmake -S <root>` with no `CMakeLists.txt` and
dump a configure failure into quickfix. Check for `CMakeLists.txt` first, with a direct message
(e.g. "Not a CMake project (no CMakeLists.txt in <root>)"), and test it.

### 3. Re-run the magister checks after the last edits — should fix (verification)

From the report:

```
My last two edits were a comment rewording and forgetting a refused preset pick; I re-tested the
second on scratch, but didn't re-run the magister drivers after them.
```

**Comment:** Thank you for saying so. After this round's changes, re-run at least
`:VimspectorInitCpp!` in magister (the file must come out the same) and the `magister: Launch`
driver up to the stop at `main.cpp:1476`, so the evidence matches the code being committed.

### 4. `vimspector#ClearBreakpoints()` leaves breakpoints in lldb-dap — should fix (doc)

**Comment:** Clearing all breakpoints mid-session doesn't send `setBreakpoints` for the emptied
files, so lldb-dap keeps stopping at them. It's not a key in this config, but Vimspector's
breakpoints window can trigger it, and the user would see "cleared" breakpoints still firing.
Add it to the plan's "Findings carried into the plan", and add it to step 9's `CLAUDE.md` items
as a known issue: clear breakpoints one by one, or restart the session. Also note in the findings
that the step-6 evidence didn't depend on it: those drivers cleared single lines, or the
re-stops were explained.

### 5. Plan text vs. what was built — should fix (doc)

`plans/cpp-debugging.md`, step 7

```markdown
      (magister: `build/debug`). Without presets, fall back to `build/` and configure with
      `-DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`.
...
- [ ] Verify on magister: `:VimspectorInitCpp` → pick `magister` → the window opens and renders the
      triangle under the debugger. If Vulkan can't find a driver, add the needed variables
      (from `$VULKAN_HOME/setup-env.sh`) to the generated config's `env`.
```

**Comment:** Update to match the code and the evidence:
- `-DCMAKE_BUILD_TYPE=Debug` only on the first configure, and why;
- Vulkan needed no `env` (system ICDs in `/usr/local/share/vulkan/icd.d/`; console shows "Draw
  Fence Created");
- generated launch configs use `args: []`, not a prompt;
- `:CMakeDebug [target]` semantics: its own picker, builds only that target, never regenerates
  `.vimspector.json`.

### 6. No progress during a long configure — no change; user to judge

`lua/config/cmake_debug.lua:305-315`

```lua
local function run(cmd, cwd, on_exit)
  busy = true
  vim.system(cmd, { cwd = cwd, text = true }, function(result)
```

**Comment:** Output is collected and handed over when the command exits. During a first
FetchContent configure that can take minutes, the only sign of life is the initial
"CMake: cmake --preset debug" notification. Neovim stays responsive, which is what matters.
Streaming progress would mean `stdout` callbacks and partial-line handling, which isn't worth it
yet. It's in the user's manual checklist to judge.

### 7. Smaller points — no change

- `ERRORFORMAT`'s `%D` "Entering directory" fallback was never actually exercised: both Make and
  Ninja printed absolute paths. It's harmless, and the comment says why it's there.
- `launch_targets()` strips only whole-line `//` comments before `vim.json.decode`. That's enough
  for the generated file, and the comment says so. A hand-edited file with inline comments would
  give empty completion. Acceptable.
- The comments are dense but they explain *why* (build-type flip, hidden-not-inherited, the
  `filetypes` filter in Vimspector's picker), and match the repo's style.

## Required before approval

- [ ] Finding 2: `CMakeLists.txt` guard in `M.debug` with a clear message; test it.
- [ ] Finding 3: re-run `:VimspectorInitCpp!` and the `magister: Launch` driver after this
      round's edits.
- [ ] Finding 4: `ClearBreakpoints` quirk into the plan findings and step 9.
- [ ] Finding 5: plan step 7 text updated.
- [ ] Finding 1: plan wording, **after the user decides**.

## Needs the user

- **Decision (finding 1):** reword the `engine.cpp` checks (recommended), or change magister so
  it calls into `engine.cpp`.
- **Manual checks**, batched with the deferred step-6 checks; sent to the user together with this
  review.

## Step 7 checklist status

| Item | Status |
| --- | --- |
| CMake-aware `:VimspectorInitCpp`, per-target configs | ✅ |
| Presets first (`debug`, or ask); `build/` fallback | ✅ (fallback deviates by design, finding 5) |
| Never use the in-source root `CMakeCache.txt` | ✅ |
| File API codemodel discovery | ✅ |
| Only the project's own targets (exactly 2 in magister) | ✅ |
| `cwd` = executable's dir | ✅ |
| Refuse non-Debug/RelWithDebInfo | ✅ |
| `:CMakeDebug` build-then-debug, errors in quickfix | ✅ ⚠️ finding 2 |
| magister window renders under the debugger | ✅ headless (console); ⏳ visual (user) |
| Breakpoints in library code and render loop | ✅ `engine.h:17`, `main.cpp:1476`; ⚠️ `engine.cpp` (finding 1) |
| Pause / continue while rendering | ✅ headless; ⏳ user |
| GoogleTest body | ✅ |
| Edit → `:CMakeDebug` rebuild, breakpoint still binds | ✅ with `touch`; ⏳ real edit (user) |
| magister `.gitignore` | ✅ (uncommitted; the user commits it) |
