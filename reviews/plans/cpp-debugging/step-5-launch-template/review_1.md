# Step 5 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 5 "Launch configuration template" |
| Branch | `cpp-debugging` (uncommitted, on top of `70fe429`) |
| Files reviewed | `templates/vimspector-cpp.json` (new), `lua/config/commands.lua` (+32) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** The code is right; the plan has to carry the new exception-block requirement into steps 6 and 7. |

## Summary

This is the first time a real Vimspector session drove lldb-dap. It works: the breakpoint was
hit within 250 ms, the stack and locals came back, and the program exited cleanly. The
subagent's investigation turned up two requirements the plan didn't have:

- **`"request": "launch"` is mandatory.** Vimspector builds the request from
  `_launch_config['request']` with no default (`debug_session.py:1958`).
- **`breakpoints.exception` must answer lldb-dap's four exception filters.** Without it,
  Vimspector asks four Y/N questions on every launch. Headless, that stalled the launch until it
  timed out after 15 s.

The command is small and already set up for step 7: `write_vimspector_json(lines, force)` can
take generated lines. It copies the template instead of parsing it, so the comments survive.
The `sourceMap` remap test went further than asked: it proved remapping works without touching
`initCommands`, so the `std::expected` formatter import survives.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files | `git status --porcelain --untracked-files=all` | ` M lua/config/commands.lua`, `?? templates/vimspector-cpp.json` ✅ |
| Create in empty dir | `nvim --headless "+VimspectorInitCpp" "+qa"` | `Wrote …/review_init/.vimspector.json` ✅ |
| Byte-identical to template | `cmp .vimspector.json templates/vimspector-cpp.json` | identical ✅ |
| Refuses overwrite | second `+VimspectorInitCpp` | `… already exists; use :VimspectorInitCpp! to overwrite it` ✅ |
| **Real launch via Vimspector** | `DRIVE_OUT=… nvim --headless main.cpp "+luafile drive.lua"` in `step5/proj` | see below ✅ |

Reviewer's launch run:

```
STOPPED after 250 ms; signs: vimspectorPCBP@5
  |   524288: add(int, int)@main.cpp:5
  |   524289: main@main.cpp:11
  | - Scope: Locals
signs after continue:
  | total=4 argc=3
  | Process 67537 exited with status = 0 (0x00000000)
```

`argc=3` confirms `"*${args}"` split `x "y z"` into two arguments.

I also checked whether the exception block could move into the step-1 adapter definition, so
each configuration wouldn't have to repeat it. **It can't.** Vimspector reads it from the
configuration entry, not the adapter:

```python
# debug_session.py:2057-2058
    self._breakpoints.SetConfiguredBreakpoints(
      self._configuration.get( 'breakpoints', {} ) )
```

`self._configuration` is the `.vimspector.json` entry. The adapter's `configuration` block is
merged into `_launch_config` (the DAP launch arguments), which is a different dictionary. So
every configuration has to carry its own block.

## Findings

### 1. The exception block must go into every configuration — should fix (plan)

`templates/vimspector-cpp.json`

```jsonc
        // Answers lldb-dap's exception filters up front; without this, every launch asks
        // four Y/N questions. Set "cpp_throw": "Y" to stop wherever a C++ exception is thrown.
        "breakpoints": {
          "exception": {
            "cpp_throw": "N",
            "cpp_catch": "N",
            "objc_throw": "N",
            "objc_catch": "N"
          }
        },
```

**Comment:** The values are right. All `"N"` matches lldb-dap's own defaults, and the comment
says how to turn `cpp_throw` on. The risk is in later steps. Step 6 adds two attach
configurations and step 7 *generates* one launch and one attach entry per CMake target. If any
of them leaves out this block, that configuration goes back to the four prompts. Update the plan:

- **Step 5:** list `"request": "launch"` and the `breakpoints.exception` block among the
  template's fields, with the reason for each.
- **Step 6:** add a sentence that each attach configuration needs the same `breakpoints.exception`
  block (per-configuration only, `debug_session.py:2057-2058`).
- **Step 7:** same requirement for every generated configuration. Also note that generated
  output can't merge with the commented template via `vim.json.decode`, so it should be generated
  outright. The subagent raised this.
- **"Findings carried into the plan":** add one bullet with the rule, so it's visible outside
  any single step.

### 2. `${program}` only accepts relative paths — no change

`templates/vimspector-cpp.json`

```jsonc
          // ${program} is relative to this file's directory (${workspaceRoot}).
          "program": "${workspaceRoot}/${program}",
```

**Comment:** An absolute answer produces `<root>//abs/path`. The comment already says to give a
relative path, and step 7 replaces this entry with real target paths for CMake projects. No
change.

### 3. `commands.lua` — no change

```lua
    -- writefile raises E482 (rather than returning -1) when called through vim.fn.
    local ok, result = pcall(vim.fn.writefile, lines, target)
```

**Comment:** The subagent checked the comment's claim rather than assuming it, and tested the
read-only-dir case. The cwd-as-root rule is the same as step 4's, and the header comment explains
the one case where it matters (Vimspector searches upward from the buffer). Splitting the write
logic out for step 7 is the right size of abstraction. No change.

### 4. The prompts haven't been seen in a real UI — defer to step 8

**Comment:** Headless, `${program}` / `${args}` came from `LaunchWithSettings`, so the prompt
path (`utils.py:700-707`) is cited but hasn't been watched. Step 8's end-to-end run is the
natural place for the user to see it: F5 → "Enter value for program". No user action needed
now.

## Required before approval

- [ ] Finding 1: update plan steps 5, 6 and 7 and "Findings carried into the plan" as described.

## Needs the user (manual)

None now. Interactive prompts are checked in step 8.

## Step 5 checklist status

| Item | Status |
| --- | --- |
| `templates/vimspector-cpp.json` generic `Launch` entry | ✅ (+ `request`, + `breakpoints.exception`) |
| Path remapping via `sourceMap`, never `initCommands` | ✅ (commented example; remap verified) |
| `:VimspectorInitCpp` with `!` overwrite rule | ✅ |
